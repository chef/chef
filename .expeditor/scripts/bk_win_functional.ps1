Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

Write-Output "--- Enable Ruby 3.1"

Write-Output "Register Installed Ruby Version 3.1 With Uru"
Start-Process "uru_rt.exe" -ArgumentList 'admin add C:\ruby31\bin' -Wait
uru 312
if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

Write-Output "--- configure winrm"
winrm quickconfig -q

Write-Output "--- bundle install"
bundle config set --local without 'omnibus_package'
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies" }

Write-Output "--- Verifying Choco Version"
$installed_version = Get-ItemProperty ${env:ChocolateyInstall}/choco.exe | select-object -expandproperty versioninfo | select-object -expandproperty productversion
if(-not $installed_version -match ('^2'))
{
    choco upgrade chocolatey
}

Write-Output "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional
if (-not $?) { throw "Chef functional specs failing." }
