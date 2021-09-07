echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

choco --version
ruby -v
bundle --version

echo "--- bundle install"
bundle config set --local without omnibus_package docgen chefstyle
bundle install --jobs=3 --retry=3

echo "+++ bundle exec rspec chocolatey_package_spec"
bundle exec rspec spec/functional/resource/chocolatey_package_spec.rb

exit $LASTEXITCODE