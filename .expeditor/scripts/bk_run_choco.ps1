$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

choco --version

echo "+++ bundle exec rspec chocolatey_package_spec"
bundle exec rspec spec/functional/resource/chocolatey_package_spec.rb
if (-not $?) { throw "Chef chocolatey functional tests failing." }
