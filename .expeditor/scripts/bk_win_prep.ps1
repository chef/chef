echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

echo "--- update bundler"

ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

$env:BUNDLER_VERSION=$(findstr bundler omnibus_overrides.rb | %{ $_.split(" ")[3] })
$env:BUNDLER_VERSION=($env:BUNDLER_VERSION -replace '"', "")
echo $env:BUNDLER_VERSION

gem install bundler -v $env:BUNDLER_VERSION --force --no-document --quiet
if (-not $?) { throw "Unable to update Bundler" }
bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package
if (-not $?) { throw "Unable to install gem dependencies" }
