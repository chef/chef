#
# Cookbook:: end_to_end
# Recipe:: _chocolatey_installer
#
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Integration tests for the chocolatey_installer resource.
#
# Scenario coverage:
#   1. Standard install from chocolatey.org (default path)
#   2. Idempotency - second converge must be a no-op
#   3. Uninstall
#   4. Install from a direct .nupkg URL (air-gapped / custom-server scenario)
#      This is the primary scenario covered by the bug fix: previously the
#      resource only downloaded the nupkg and never ran the installer.
#   5. Idempotency after nupkg-URL install
#   6. Recovery when an installed Chocolatey is missing its package registration
#   7. Adding/enabling a source and installing a dependent package in the same run
#

require "zip"

# 1. Standard install from the official Chocolatey community repository.
chocolatey_installer "Install Chocolatey (default)" do
  action :install
end

# 2. Idempotency check: running the same install a second time must produce no changes.
chocolatey_installer "Install Chocolatey (default idempotent)" do
  action :install
end

# 3. Uninstall so we can exercise the full install path again from a clean state.
chocolatey_installer "Uninstall Chocolatey" do
  action :uninstall
end

# Reject an archive entry whose resolved path shares the extraction-root prefix
# but is not a child of the extraction root.
unsafe_nupkg_path = ::File.join(Chef::Config[:file_cache_path], "unsafe-chocolatey.nupkg")
ruby_block "Assert Chocolatey installer rejects paths outside the extraction root" do
  block do
    Zip::OutputStream.open(unsafe_nupkg_path) do |zip|
      zip.put_next_entry("../extract-escape/marker.txt")
      zip.write("unused")
    end

    installer = Chef::Resource::ChocolateyInstaller.new("Reject unsafe Chocolatey archive", run_context)
    installer.download_url(unsafe_nupkg_path)
    begin
      installer.run_action(:install)
    rescue StandardError => e
      raise unless e.message.include?("Unsafe path in Chocolatey package")
    else
      raise "Chocolatey installer accepted an archive entry outside the extraction root"
    ensure
      ::File.delete(unsafe_nupkg_path) if ::File.exist?(unsafe_nupkg_path)
    end
  end
end

# 4. Install from a direct .nupkg URL.  This exercises the air-gapped fix:
#    download the nupkg, extract it, and run tools/chocolateyInstall.ps1.
#    We pin a specific version so CI results are reproducible.
#
#    MAINTENANCE NOTE: The URL below uses the Chocolatey CDN at packages.chocolatey.org.
#    If that domain or URL format changes, or if a newer pinned version is needed,
#    update both this URL and the version assertion in:
#      kitchen-tests/test/integration/end-to-end/_chocolatey_installer.rb
#    Verify the new URL ends in .nupkg — the resource validates the file extension
#    and will raise Chef::Exceptions::ValidationFailed if it does not.
chocolatey_installer "Install Chocolatey from nupkg URL" do
  action :install
  download_url "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end

# 5. Idempotency check after nupkg-URL install.
chocolatey_installer "Install Chocolatey from nupkg URL (idempotent)" do
  action :install
  download_url "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end

# Simulate a prior install whose choco.exe exists but whose nupkg registration
# was omitted by an older Chef release. The original downloaded archive remains
# in Chef's cache and must be version-checked before it is used for repair.
ruby_block "Simulate legacy Chocolatey installation missing package registration" do
  block do
    registered_nupkg = ::File.join(ENV["ALLUSERSPROFILE"], "chocolatey", "lib", "chocolatey", "chocolatey.nupkg")
    ::File.delete(registered_nupkg) if ::File.file?(registered_nupkg)
  end
end

ruby_block "Reject incorrect Chocolatey package IDs during recovery" do
  block do
    archive = ::File.join(Chef::Config[:file_cache_path], "invalid-chocolatey.nupkg")
    registered_nupkg = ::File.join(ENV["ALLUSERSPROFILE"], "chocolatey", "lib", "chocolatey", "chocolatey.nupkg")
    begin
      [nil, "other-package"].each do |id|
        Zip::OutputStream.open(archive) do |zip|
          zip.put_next_entry("chocolatey.nuspec")
          id_element = id ? "<id>#{id}</id>" : ""
          zip.write("<package><metadata>#{id_element}<version>2.4.2</version></metadata></package>")
        end
        installer = Chef::Resource::ChocolateyInstaller.new("Reject invalid Chocolatey package ID", run_context)
        installer.download_url(archive)
        begin
          installer.run_action(:install)
        rescue StandardError => e
          raise unless e.message.include?("package ID is not chocolatey")
        else
          raise "Chocolatey installer accepted an invalid package ID"
        end
        raise "Chocolatey package was registered despite an invalid ID" if ::File.exist?(registered_nupkg)
      end
    ensure
      ::File.delete(archive) if ::File.exist?(archive)
    end
  end
end

ruby_block "Reject mismatched Chocolatey package during recovery" do
  block do
    archive = ::File.join(Chef::Config[:file_cache_path], "mismatched-chocolatey.nupkg")
    registered_nupkg = ::File.join(ENV["ALLUSERSPROFILE"], "chocolatey", "lib", "chocolatey", "chocolatey.nupkg")
    begin
      Zip::OutputStream.open(archive) do |zip|
        zip.put_next_entry("chocolatey.nuspec")
        zip.write("<package><metadata><id>chocolatey</id><version>0.0.1</version></metadata></package>")
      end
      installer = Chef::Resource::ChocolateyInstaller.new("Reject mismatched Chocolatey package", run_context)
      installer.download_url(archive)
      begin
        installer.run_action(:install)
      rescue StandardError => e
        raise unless e.message.include?("does not match installed version")
      else
        raise "Chocolatey installer accepted a mismatched package"
      end
      raise "Chocolatey package was registered despite a version mismatch" if ::File.exist?(registered_nupkg)
    ensure
      ::File.delete(archive) if ::File.exist?(archive)
    end
  end
end

ruby_block "Repair Chocolatey package registration with a conflicting environment root" do
  block do
    original_root = ENV["ChocolateyInstall"]
    begin
      ENV["ChocolateyInstall"] = ::File.join(Chef::Config[:file_cache_path], "other-chocolatey")
      installer = Chef::Resource::ChocolateyInstaller.new("Repair Chocolatey package registration", run_context)
      installer.download_url("https://packages.chocolatey.org/chocolatey.2.4.2.nupkg")
      installer.run_action(:install)
      registered_nupkg = ::File.join(ENV["ALLUSERSPROFILE"], "chocolatey", "lib", "chocolatey", "chocolatey.nupkg")
      raise "Chocolatey registration was not repaired at the installed root" unless ::File.file?(registered_nupkg)
    ensure
      ENV["ChocolateyInstall"] = original_root
    end
  end
end

# 7. The customer's failing sequence: after installing from a custom .nupkg URL,
#    add and enable a source in the same Chef run.
chocolatey_source "chef-kitchen-test-source" do
  source "https://community.chocolatey.org/api/v2/"
  priority 10
  action %i{add disable enable}
end

chocolatey_source "chef-kitchen-test-source (idempotent)" do
  source_name "chef-kitchen-test-source"
  source "https://community.chocolatey.org/api/v2/"
  priority 10
  action :add
end

ruby_block "Assert chocolatey_source add is idempotent" do
  block do
    if resources("chocolatey_source[chef-kitchen-test-source (idempotent)]").updated_by_last_action?
      raise "chocolatey_source converged again after being added"
    end
  end
end

# 8. Install a package that depends on the chocolatey package, after the nupkg install.
#    chocolatey-community-validation.extension declares a dependency on
#    chocolatey (>= 2.0.0). The nupkg install must register chocolatey in
#    lib\chocolatey, as Chocolatey's install.ps1 does. If it did not, choco would
#    try to fetch chocolatey from the feed (the customer-reported failure with
#    chocolatey.extension) and could replace the pinned 2.4.2. The InSpec
#    controls assert the package is installed and chocolatey is still 2.4.2:
#      kitchen-tests/test/integration/end-to-end/_chocolatey_installer.rb
chocolatey_package "chocolatey-community-validation.extension" do
  version "0.2.0"
  options "--no-progress"
  action :install
end
