# Integration verification for chocolatey_installer resource.
# Chocolatey is Windows-only; skip all controls on non-Windows platforms.
if os.windows?

  choco_bin = 'C:\ProgramData\chocolatey\bin\choco.exe'
  choco_config = 'C:\ProgramData\chocolatey\config\chocolatey.config'

  # choco.exe must exist — this is the primary indicator that the installer
  # ran to completion, not just that the nupkg was downloaded.
  describe file(choco_bin) do
    it { should exist }
  end

  # The chocolatey.config must exist — its absence was the symptom of the
  # original bug (chocolatey_source would fail with "Could not find the
  # Chocolatey config").
  describe file(choco_config) do
    it { should exist }
  end

  # choco must be executable and return a valid version string.
  describe command("choco --version") do
    its("exit_status") { should eq 0 }
    its("stdout") { should match(/\d+\.\d+\.\d+/) }
  end

  # The installed version must match the nupkg we specified.
  describe command("choco --version") do
    its("stdout") { should match(/^2\.4\.2/) }
  end

  # choco must be able to list local packages without error — validates that
  # the full Chocolatey environment (PATH, ChocolateyInstall env var, etc.)
  # was set up correctly by the installer and not just partially initialized.
  # Note: --local-only was deprecated in Chocolatey 2.x; plain `choco list`
  # defaults to local-only in 2.x and is the correct form.
  describe command("choco list") do
    its("exit_status") { should eq 0 }
  end

  # The nupkg install must register chocolatey as an installed package (as
  # Chocolatey's install.ps1 does); otherwise packages that depend on chocolatey,
  # such as chocolatey.extension, try to install it again from the feed.
  describe file('C:\ProgramData\chocolatey\lib\chocolatey\chocolatey.nupkg') do
    it { should exist }
  end

  describe command("choco list") do
    its("stdout") { should match(/^chocolatey 2\.4\.2/) }
  end

  # The package that depends on chocolatey installed, and chocolatey was not
  # replaced by a newer version fetched from the feed to satisfy the dependency.
  describe command("choco list") do
    its("stdout") { should match(/^chocolatey-community-validation\.extension 0\.2\.0/) }
    its("stdout") { should match(/^chocolatey 2\.4\.2\s*$/) }
  end

end
