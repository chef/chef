Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

Write-Output "--- Enable Ruby 2.7"

Write-Output "Add Uru to Environment PATH"
$env:PATH = "C:\Program Files (x86)\Uru;" + $env:PATH
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

Write-Output "Register Installed Ruby Version 2.7 With Uru"
Start-Process "C:\Program Files (x86)\Uru\uru_rt.exe" -ArgumentList 'admin add C:\ruby27\bin' -Wait
uru 271
if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

Write-Output "--- configure winrm"
winrm quickconfig -q

# TODO - why not using bk_pwin_prop which does all this?
Write-Output "--- bundle install"
bundle config set --local without 'omnibus_package'
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies (chef-client)" }

Write-Output "+++ bundle exec rake spec:functional (chef-client) "
bundle exec rake spec:functional
if (-not $?) { throw "chef-client functional specs failing." }
Write-Output "+++ bundle exec rake spec:functional (knife)"

cd knife
bundle config set --local without 'omnibus_package'
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies (knife)" }
bundle exec rake spec:functional
if (-not $?) { throw "knife functional specs failing." }
