echo "--- system details"
$Properties = 'Caption', 'CSName', 'Version', 'BuildType', 'OSArchitecture'
Get-CimInstance Win32_OperatingSystem | Select-Object $Properties | Format-Table -AutoSize

choco --version

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

echo "+++ bundle exec rspec chocolatey_package_spec"
bundle exec rspec spec/functional/resource/chocolatey_package_spec.rb

exit $LASTEXITCODE
