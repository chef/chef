# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

# install choco as necessary
function installChoco {

  if (!(Test-Path "$($env:ProgramData)\chocolatey\choco.exe")) {
    Write-Output "Chocolatey is not installed, proceeding to install"
    try {
      write-output "installing in 3..2..1.."
      Set-ExecutionPolicy Bypass -Scope Process -Force
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
      iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    catch {
      Write-Error $_.Exception.Message
    }
  }
  else {
    Write-Output "Chocolatey is already installed"
  }
}

installChoco

# install powershell core
if ($PSVersionTable.PSVersion.Major -lt 7) {
  $TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
  [System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol
  Invoke-WebRequest "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/PowerShell-7.3.0-win-x64.msi" -UseBasicParsing -OutFile powershell.msi
  Start-Process msiexec.exe -Wait -ArgumentList "/package PowerShell.msi /quiet"
}

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
    Throw 1
  }
}

$Env:PATH = "C:\opscode\chef\bin;$Env:PATH"

chef-client --version
If ($lastexitcode -ne 0) { Throw $lastexitcode }

# Exercise various packaged tools to validate binstub shebangs
& $embedded_bin_dir\ruby --version
If ($lastexitcode -ne 0) { Throw $lastexitcode }

& $embedded_bin_dir\gem.bat --version
If ($lastexitcode -ne 0) { Throw $lastexitcode }

& $embedded_bin_dir\bundle.bat --version
If ($lastexitcode -ne 0) { Throw $lastexitcode }

& $embedded_bin_dir\rspec.bat --version
If ($lastexitcode -ne 0) { Throw $lastexitcode }

$Env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;$Env:PATH"

# Test against the vendored chef gem (cd into the output of "gem which chef")
$chefdir = gem which chef
If ($lastexitcode -ne 0) { Throw $lastexitcode }

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
If ($lastexitcode -ne 0) { Throw $lastexitcode }

# # Clear any existing bundle configs
# bundle config --delete force_ruby_platform
# bundle config --delete specific_platform

# # Set new configs
# bundle config set --local force_ruby_platform false
# bundle config set --local specific_platform true
# bundle config set --local platform x64-mingw32

Write-Output "Current directory: $(Get-Location)"
Write-Output "Gemfile location: $(Get-ChildItem Gemfile -ErrorAction SilentlyContinue | Select-Object FullName | Format-Table -HideTableHeaders | Out-String)".Trim()

# Add before bundle install command
Write-Output "Current BUNDLE_GEMFILE: $env:BUNDLE_GEMFILE"
Write-Output "Current directory: $(Get-Location)"
Write-Output "Available Gemfiles:"
Get-ChildItem -Recurse -Filter "Gemfile" | ForEach-Object {
    Write-Output "  $($_.FullName)"
}

bundle config list

bundle install
If ($lastexitcode -ne 0) { Throw $lastexitcode }

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

$format="progress"

# use $Env:OMNIBUS_TEST_FORMAT if defined
If ($Env:OMNIBUS_TEST_FORMAT) {
  $format = $Env:OMNIBUS_TEST_FORMAT
}

# # Add these lines to properly handle gem dependencies
# Write-Output "Configuring bundler and gem environment..."
# try {
#     # Set bundler configs
#     bundle config set --local force_ruby_platform true
#     bundle config set --local specific_platform true
    
#     # Clean and reinstall critical gems with --force flag
#     & $embedded_bin_dir\gem.bat uninstall -a bigdecimal
#     & $embedded_bin_dir\gem.bat install bigdecimal -v "2.0.0" --no-document
#     # & $embedded_bin_dir\gem.bat install ffi -v "1.15.5" --platform=ruby --no-document
#     # & $embedded_bin_dir\gem.bat install ffi-yajl --no-document
    
#     # Update bundle
#     # bundle update --conservative
#     # bundle install
    
#     # Verify installations
#     Write-Output "Installed versions:"
#     & $embedded_bin_dir\gem.bat list bigdecimal
#     & $embedded_bin_dir\gem.bat list ffi
#     & $embedded_bin_dir\gem.bat list ffi-yajl
# } catch {
#     Write-Error "Failed to configure gems: $_"
#     throw $_
# }

bundle exec rspec -f $format --profile -- ./spec/unit
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

bundle exec rspec -f $format --profile -- ./spec/functional
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

bundle exec rspec -f $format --profile -- ./spec/integration
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

If ($exit -ne 0) { Throw $exit }
