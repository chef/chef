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
#   2. Idempotency - a second install in the same run must not converge
#   3. Uninstall
#   4. Install from a local drive path (air-gapped, nupkg already on disk),
#      verified in-run, followed by an idempotency check and an uninstall
#   5. Install from a direct .nupkg URL (air-gapped / custom-server scenario)
#      This is the primary scenario covered by the bug fix: previously the
#      resource only downloaded the nupkg and never ran the installer.
#   6. Idempotency after nupkg-URL install
#
# Idempotency is asserted inside the run (ruby_block + updated_by_last_action?)
# because CI runs `kitchen verify`, which converges once and does not run
# Test Kitchen's idempotency_test.
#

choco_exe = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco.exe"
choco_config = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\config\\chocolatey.config"

# 1. Standard install from the official Chocolatey community repository.
chocolatey_installer "Install Chocolatey (default)" do
  action :install
end

# 2. Idempotency check: running the same install a second time must produce no changes.
chocolatey_installer "Install Chocolatey (default idempotent)" do
  action :install
end

ruby_block "Assert default chocolatey_installer install is idempotent" do
  block do
    if resources("chocolatey_installer[Install Chocolatey (default idempotent)]").updated_by_last_action?
      raise "chocolatey_installer converged again even though Chocolatey was already installed"
    end
  end
end

# 3. Uninstall so we can exercise the full install path again from a clean state.
chocolatey_installer "Uninstall Chocolatey" do
  action :uninstall
end

# 4. Install from a local drive path. The nupkg is staged on disk first, then the
#    resource must use it directly (no download), extract it and run the installer.
#    The URL below is the same pinned package used in step 5; see the maintenance
#    note there.
local_nupkg = "#{Chef::Config[:file_cache_path]}\\chocolatey.2.4.2.nupkg".tr("/", "\\")

remote_file local_nupkg do
  source "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end

chocolatey_installer "Install Chocolatey from local nupkg path" do
  action :install
  download_url local_nupkg
end

ruby_block "Assert Chocolatey was installed from the local nupkg path" do
  block do
    [choco_exe, choco_config].each do |path|
      raise "Expected #{path} to exist after installing from #{local_nupkg}" unless ::File.exist?(path)
    end
  end
end

chocolatey_installer "Install Chocolatey from local nupkg path (idempotent)" do
  action :install
  download_url local_nupkg
end

ruby_block "Assert local nupkg path install is idempotent" do
  block do
    if resources("chocolatey_installer[Install Chocolatey from local nupkg path (idempotent)]").updated_by_last_action?
      raise "chocolatey_installer converged again after installing from a local nupkg path"
    end
  end
end

chocolatey_installer "Uninstall Chocolatey after local nupkg path install" do
  action :uninstall
end

# 5. Install from a direct .nupkg URL.  This exercises the air-gapped fix:
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

# 6. Idempotency check after nupkg-URL install.
chocolatey_installer "Install Chocolatey from nupkg URL (idempotent)" do
  action :install
  download_url "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end

ruby_block "Assert nupkg URL install is idempotent" do
  block do
    if resources("chocolatey_installer[Install Chocolatey from nupkg URL (idempotent)]").updated_by_last_action?
      raise "chocolatey_installer converged again after installing from a nupkg URL"
    end
  end
end
