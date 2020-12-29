echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

echo "ruby version:"
ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

echo "bundler version: "
bundle --version
if (-not $?) { throw "Can't run Bundler. Is it installed?" }

echo "--- bundle install"
bundle install --jobs=3 --retry=3  --path=vendor/bundle --without omnibus_package
if (-not $?) { throw "Unable to install gem dependencies" }