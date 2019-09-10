echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize
ruby -v
bundle --version

echo "--- bundle install"
bundle install --jobs=3 --retry=3 --without omnibus_package docgen chefstyle

echo "+++ bundle exec rake"
bundle exec rake spec:functional

exit $LASTEXITCODE