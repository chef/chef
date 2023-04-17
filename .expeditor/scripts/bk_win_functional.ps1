Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

# Ruby is not installed at this point for some reason. Installing it now
$pkg_version="3.0.3"
$pkg_revision="1"
$pkg_source="https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-${pkg_version}-${pkg_revision}/rubyinstaller-devkit-${pkg_version}-${pkg_revision}-x64.exe"

if (Get-Command Ruby -ErrorAction SilentlyContinue){
  $old_version = Ruby --version
}
else {
  $old_version = $null
}

if(-not($old_version -match "3.0")){
  Write-Output "Downloading Ruby + DevKit";
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;
  $package_destination = "$env:temp\rubyinstaller-devkit-$pkg_version-$pkg_revision-x64.exe"
  (New-Object System.Net.WebClient).DownloadFile($pkg_source, $package_destination);
  Write-Output "`rDid the file download?"
  Test-Path $package_destination
  Write-Output "`rInstalling Ruby + DevKit";
  Start-Process $package_destination -ArgumentList "/verysilent /dir=C:\ruby30" -Wait ;
  Write-Output "Cleaning up installation";
  Remove-Item $package_destination -Force;
}

Write-Output "--- Enable Ruby 3.0"

Write-Output "Register Installed Ruby Version 3.0 With Uru"
Start-Process "uru_rt.exe" -ArgumentList 'admin add C:\ruby30\bin' -Wait
uru 30
if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

Write-Output "--- configure winrm"
winrm quickconfig -q

Write-Output "--- bundle install"
bundle config set --local without "omnibus_package"
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies" }

Write-Output "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional SPEC_OPTS='--format documentation'
if (-not $?) { throw "Chef functional specs failing." }
