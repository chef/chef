# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

# install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# install powershell core
Invoke-WebRequest "https://github.com/PowerShell/PowerShell/releases/download/v7.0.3/PowerShell-7.0.3-win-x64.msi" -UseBasicParsing -OutFile powershell.msi
Start-Process msiexec.exe -Wait -ArgumentList "/package PowerShell.msi /quiet"
$env:path += ";C:\Program Files\PowerShell\7"

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
$embedded_bin_dir = "C:\opscode\chef\embedded\bin"

# Set TEMP and TMP environment variables to a short path because buildkite-agent user's default path is so long it causes tests to fail
$Env:TEMP = "C:\cheftest"
$Env:TMP = "C:\cheftest"
Remove-Item -Recurse -Force $Env:TEMP -ErrorAction SilentlyContinue
New-Item -ItemType directory -Path $Env:TEMP

# FIXME: we should really use Bundler.with_unbundled_env in the caller instead of re-inventing it here
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

# buildkite changes the casing of the Path variable to PATH
# It is not clear how or where that happens, but it breaks the choco
# tests. Removing the PATH and resetting it with the expected casing
$p = $env:PATH
$env:PATH = $null
$env:Path = $p

# Running the specs separately fixes an edge case on 2012R2-i386 where the desktop heap's
# allocated limit is hit and any test's attempt to create a new process is met with
# exit code -1073741502 (STATUS_DLL_INIT_FAILED). after much research and troubleshooting,
# desktop heap exhaustion seems likely (https://docs.microsoft.com/en-us/archive/blogs/ntdebugging/desktop-heap-overview)
$exit = 0

bundle exec rspec -f progress --profile -- ./spec/unit
If ($lastexitcode -ne 0) { $exit = 1 }

bundle exec rspec -f progress --profile -- ./spec/functional
If ($lastexitcode -ne 0) { $exit = 1 }

bundle exec rspec -f progress --profile -- ./spec/integration
If ($lastexitcode -ne 0) { $exit = 1 }

Exit $exit
