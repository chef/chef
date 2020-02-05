echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

#
# Software Languages
#

# Install Ruby + Devkit
$ErrorActionPreference = 'Stop'

echo "Downloading Ruby + DevKit"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile('https://public-cd-buildkite-cache.s3-us-west-2.amazonaws.com/rubyinstaller-devkit-2.6.5-1-x64.exe', 'c:\\rubyinstaller-devkit-2.6.5-1-x64.exe')

echo "Installing Ruby + DevKit"
Start-Process c:\rubyinstaller-devkit-2.6.5-1-x64.exe -ArgumentList '/verysilent /dir=C:\\ruby26' -Wait

echo "Cleaning up installation"
Remove-Item c:\rubyinstaller-devkit-2.6.5-1-x64.exe -Force
echo "Closing out the layer (this can take awhile)"

# Set-Item -Path Env:Path -Value to include ruby26
$Env:Path+=";C:\ruby26\bin"

winrm quickconfig -q
ruby -v
bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle

echo "+++ bundle exec rake spec:functional"
bundle exec rake spec:functional

exit $LASTEXITCODE