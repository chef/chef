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

# 7. The customer's failing sequence: after installing from a custom .nupkg URL,
#    add and enable a source with chocolatey_source in the same Chef run.
#
#    WHY THE :disable ACTION IS HERE (TEST-ONLY; do not remove it as "redundant"):
#    This is purely a testing device.  Real-world recipes never need to disable
#    a source before enabling it; adding a source already leaves it enabled.
#    A newly added Chocolatey source is already enabled, and the :enable action
#    only converges when the source is currently disabled (it is a no-op
#    otherwise).  Running :add then :enable would therefore never execute the
#    `choco source enable` code path, so the enable half of the customer's
#    sequence would pass without being tested.  The :disable step puts the
#    source in the disabled state so that :enable has real work to do.  It is
#    test-only device, not part of the customer's scenario.  The final state
#    (present and enabled) is asserted in:
#      kitchen-tests/test/integration/end-to-end/_chocolatey_installer.rb
#    If :disable is removed, that control still passes but :enable is no longer
#    exercised.
chocolatey_source "chef-kitchen-test-source" do
  source "https://community.chocolatey.org/api/v2/"
  priority 10
  action %i{add disable enable}
end

# Idempotency: re-adding the same source must not converge again.
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
