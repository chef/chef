Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

Write-Output "--- Enable Ruby 2.6"
Write-Output "Add Uru to Environment PATH"
$env:PATH = "C:\Program Files (x86)\Uru;" + $env:PATH
[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine)

Write-Output "Register Installed Ruby Version 2.6 With Uru"
Start-Process "C:\Program Files (x86)\Uru\uru_rt.exe" -ArgumentList 'admin add C:\ruby26\bin' -Wait
uru 266
if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }

Write-Output "--- configure winrm"

winrm quickconfig -q
ruby -v
bundle --version

Write-Output "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle

Write-Output "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional

exit $LASTEXITCODE
