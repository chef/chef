# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

$channel = "$Env:CHANNEL"
If ([string]::IsNullOrEmpty($channel)) { $channel = "unstable" }

$product = "$Env:PRODUCT"
If ([string]::IsNullOrEmpty($product)) { $product = "chef" }

$version = "$Env:VERSION"
If ([string]::IsNullOrEmpty($version)) { $version = "latest" }

Write-Output "--- Installing $channel $product $version"
$package_file = $(C:\opscode\omnibus-toolchain\bin\install-omnibus-product.ps1 -Product "$product" -Channel "$channel" -Version "$version" | Select-Object -Last 1)

Write-Output "--- Verifying omnibus package is signed"
C:\opscode\omnibus-toolchain\bin\check-omnibus-package-signed.ps1 "$package_file"

Write-Output "--- Running verification for $channel $product $version"

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
$embedded_bin_dir = "C:\opscode\$product\embedded\bin"

# Set TEMP and TMP environment variables to a short path because buildkite-agent user's default path is so long it causes tests to fail
$Env:TEMP = "C:\cheftest"
$Env:TMP = "C:\cheftest"
Remove-Item -Recurse -Force $Env:TEMP -ErrorAction SilentlyContinue
New-Item -ItemType directory -Path $Env:TEMP

ForEach ($b in
  "chef-client",
  "knife",
  "chef-solo",
  "ohai"
) {
  Write-Output "Checking for existence of binfile $b..."

  If (Test-Path -PathType Leaf -Path "C:\opscode\$product\bin\$b") {
    Write-Output "Found $b!"
  }
  Else {
    Write-Output "Error: Could not find $b"
    exit 1
  }
}

$Env:PATH = "C:\opscode\$product\bin;$Env:PATH"

chef-client --version

# Exercise various packaged tools to validate binstub shebangs
& $embedded_bin_dir\ruby --version
& $embedded_bin_dir\gem.bat --version
& $embedded_bin_dir\bundle.bat --version
& $embedded_bin_dir\rspec.bat --version

$Env:PATH = "C:\opscode\$product\bin;C:\opscode\$product\embedded\bin;$Env:PATH"

# Test against the vendored chef gem (cd into the output of "gem which chef")
$chefdir = gem which chef
$chefdir = Split-Path -Path "$chefdir" -Parent
$chefdir = Split-Path -Path "$chefdir" -Parent
Set-Location -Path $chefdir

Get-Location

# ffi-yajl must run in c-extension mode for perf, so force it so we don't accidentally fall back to ffi
$Env:FORCE_FFI_YAJL = "ext"

# chocolatey functional tests fail so delete the chocolatey binary to avoid triggering them
Remove-Item -Path C:\ProgramData\chocolatey\bin\choco.exe -ErrorAction SilentlyContinue

# some tests need winrm configured
winrm quickconfig -quiet

bundle
If ($lastexitcode -ne 0) { Exit $lastexitcode }

bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec/functional
If ($lastexitcode -ne 0) { Exit $lastexitcode }
