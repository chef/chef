echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

# Set-Item -Path Env:Path -Value ($Env:Path + ";C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin") 
$Env:Path="C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\ruby26\bin;C:\ci-studio-common\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\ProgramData\chocolatey\bin;C:\Program Files\Git\cmd;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;C:\Go\bin;C:\Users\ContainerAdministrator\go\bin"

winrm quickconfig -q

echo "--- update bundler and rubygems"

ruby -v

$env:RUBYGEMS_VERSION=$(findstr rubygems omnibus_overrides.rb | %{ $_.split(" ")[3] })
$env:BUNDLER_VERSION=$(findstr bundler omnibus_overrides.rb | %{ $_.split(" ")[3] })

$env:RUBYGEMS_VERSION=($env:RUBYGEMS_VERSION -replace '"', "")
$env:BUNDLER_VERSION=($env:BUNDLER_VERSION -replace '"', "")

echo $env:RUBYGEMS_VERSION
echo $env:BUNDLER_VERSION

gem update --system $env:RUBYGEMS_VERSION
gem --version
gem install bundler -v $env:BUNDLER_VERSION --force --no-document --quiet
bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle

echo "+++ bundle exec rake spec:integration"
bundle exec rake spec:integration

exit $LASTEXITCODE
