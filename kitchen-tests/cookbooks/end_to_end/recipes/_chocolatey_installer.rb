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
#

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
  action    :install
  download_url "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end

# 5. Idempotency check after nupkg-URL install.
chocolatey_installer "Install Chocolatey from nupkg URL (idempotent)" do
  action    :install
  download_url "https://packages.chocolatey.org/chocolatey.2.4.2.nupkg"
end
