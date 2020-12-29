echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

ruby -v
if (-not $?) { throw "Can't run Ruby. Is it installed?" }

bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package
if (-not $?) { throw "Unable to install gem dependencies" }
