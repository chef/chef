Write-Output "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

$ErrorActionPreference = 'Stop'

Write-Output "--- Enable Ruby 3.0`r"

Write-Output  "Installing Ruby 3.0 and refreshing the path"

Write-Output "`r Removing the old Choco directory with Force!"
Remove-Item -path "C:\ProgramData\chocolatey" -Recurse -Force -ErrorAction SilentlyContinue

Write-Output "`r Now verifying the \Programdata directory"
$output = Get-ChildItem -Path "C:\ProgramData"
foreach($dir in $output){Write-Output $dir}
Write-Output "`r`n"

Write-Output "`r Forcing an installation"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Write-Output "Is fucking Choco installed or Not?"
Get-Command -Name choco
Write-Output "`r`n"

Write-Output "here's my path :`r`n"
Write-Output $env:path
Write-Output "`r`n"

choco install ruby --version=3.0.5.1 --package-parameters="'/InstallDir:C:\ruby30'" -y
refreshenv
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") +  ";C:\Ruby30\bin"
ruby -v

# Write-Output "Register Installed Ruby Version 3.0 With Uru"
# Start-Process "uru_rt.exe" -ArgumentList 'admin add C:\ruby27\bin' -Wait
# uru 30
# if (-not $?) { throw "Can't Activate Ruby. Did Uru Registration Succeed?" }
# ruby -v
# if (-not $?) { throw "Can't run Ruby. Is it installed?" }

Write-Output "--- configure winrm"
winrm quickconfig -q

Write-Output "--- bundle install"
bundle config set --local without 'omnibus_package'
bundle install --jobs=3 --retry=3
if (-not $?) { throw "Unable to install gem dependencies" }

Write-Output "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional
if (-not $?) { throw "Chef functional specs failing." }
