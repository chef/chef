# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

# install chocolatey
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
      Write-Output "Chocolatey is already installed, upgrading"
      choco feature enable -n=allowGlobalConfirmation
      choco upgrade chocolatey
  }
}

installChoco

# install powershell core
if ($PSVersionTable.PSVersion.Major -lt 7) {
  $TLS12Protocol = [System.Net.SecurityProtocolType] 'Ssl3 , Tls12'
  [System.Net.ServicePointManager]::SecurityProtocol = $TLS12Protocol
}
Invoke-WebRequest "https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/PowerShell-7.3.0-win-x64.msi" -UseBasicParsing -OutFile powershell.msi
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

Write-Host "--- Setting CHEF_LICENSE_SERVER environment variable"
# Define the path to the license server URL file relative to $PSScriptRoot
$LicenseServerFile = Join-Path -Path $PSScriptRoot -ChildPath "../.expeditor/scripts/chef_license_server_url.txt"
# Read the CHEF_LICENSE_SERVER value from the file
$CHEF_LICENSE_SERVER = Get-Content -Path $LicenseServerFile
# Set the environment variable
$env:CHEF_LICENSE_SERVER = $CHEF_LICENSE_SERVER
# Output the CHEF_LICENSE_SERVER environment variable
Write-Host "--- CHEF_LICENSE_SERVER URL: $env:CHEF_LICENSE_SERVER"

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

# We add C:\Program Files\Git\bin to the path to ensure the git bash shell is included
# Omnibus puts C:\Program Files\Git\mingw64\bin which has git.exe but not bash.exe
$Env:PATH = "C:\opscode\chef\bin;C:\opscode\chef\embedded\bin;C:\Program Files\Git\bin;$Env:PATH"

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

# temp fix until we figure out whats going on in our specific environment as it pertains to unf_ext#
gem install unf_ext -v 0.0.8.2 --source https://rubygems.org/gems/unf_ext

bundle
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

bundle exec rspec -f progress --profile -- ./spec/unit
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

bundle exec rspec -f progress --profile -- ./spec/functional
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

bundle exec rspec -f progress --profile -- ./spec/integration
If ($lastexitcode -ne 0) { $exit = 1 }
Write-Output "Last exit code: $lastexitcode"
Write-Output ""

If ($exit -ne 0) { Throw $exit }
