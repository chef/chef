# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
$embedded_bin_dir = "C:\opscode\chef\embedded\bin"

# Set TEMP and TMP environment variables to a short path because buildkite-agent user's default path is so long it causes tests to fail
$Env:TEMP = "C:\cheftest"
$Env:TMP = "C:\cheftest"
Remove-Item -Recurse -Force $Env:TEMP -ErrorAction SilentlyContinue
New-Item -ItemType directory -Path $Env:TEMP

# FIXME: we should really use Bundler.with_clean_env in the caller instead of re-inventing it here
Remove-Item Env:_ORIGINAL_GEM_PATH -ErrorAction SilentlyContinue
Remove-Item Env:BUNDLE_BIN_PATH -ErrorAction SilentlyContinue
Remove-Item Env:BUNDLE_GEMFILE -ErrorAction SilentlyContinue
Remove-Item Env:GEM_HOME -ErrorAction SilentlyContinue
Remove-Item Env:GEM_PATH -ErrorAction SilentlyContinue
Remove-Item Env:GEM_ROOT -ErrorAction SilentlyContinue
Remove-Item Env:RUBYLIB -ErrorAction SilentlyContinue
Remove-Item Env:RUBYOPT -ErrorAction SilentlyContinue
Remove-Item Env:RUBY_ENGINE -ErrorAction SilentlyContinue
Remove-Item Env:RUBY_ROOT -ErrorAction SilentlyContinue
Remove-Item Env:RUBY_VERSION -ErrorAction SilentlyContinue
Remove-Item Env:BUNDLER_VERSION -ErrorAction SilentlyContinue

ForEach ($b in
  "chef-client",
  "knife",
  "chef-solo",
  "ohai"
) {
  Write-Output "Checking for existence of binfile $b..."

  If (Test-Path -PathType Leaf -Path "C:\opscode\chef\bin\$b") {
    Write-Output "Found $b!"
  }
  Else {
    Write-Output "Error: Could not find $b"
    exit 1
  }
}

$Env:PATH = "C:\opscode\chef\bin;$Env:PATH"

chef-client --version

# Exercise various packaged tools to validate binstub shebangs
& $embedded_bin_dir\ruby --version
& $embedded_bin_dir\gem.bat --version
& $embedded_bin_dir\bundle.bat --version
& $embedded_bin_dir\rspec.bat --version

$Env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;$Env:PATH"

# Test against the vendored chef gem (cd into the output of "gem which chef")
$chefdir = gem which chef
$chefdir = Split-Path -Path "$chefdir" -Parent
$chefdir = Split-Path -Path "$chefdir" -Parent
Set-Location -Path $chefdir

Get-Location

# ffi-yajl must run in c-extension mode for perf, so force it so we don't accidentally fall back to ffi
$Env:FORCE_FFI_YAJL = "ext"

# accept license
$Env:CHEF_LICENSE = "accept-no-persist"

# some tests need winrm configured
winrm quickconfig -quiet

bundle
If ($lastexitcode -ne 0) { Exit $lastexitcode }

# FIXME: we need to add back unit and integration tests here.  we have no coverage of those on e.g. AIX
#
# chocolatey functional tests fail so disable that tag directly <-- and this is a bug that needs fixing.
bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation --tag ~choco_installed spec/functional
If ($lastexitcode -ne 0) { Exit $lastexitcode }
