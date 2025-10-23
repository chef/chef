# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

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

$original_location = Get-Location
$chefdir = gem which chef
If ($lastexitcode -ne 0) { Throw $lastexitcode }

$chefdir = Split-Path -Path "$chefdir" -Parent
$chefdir = Split-Path -Path "$chefdir" -Parent

# ffi-yajl must run in c-extension mode for perf, so force it so we don't accidentally fall back to ffi
$Env:FORCE_FFI_YAJL = "ext"

# accept license
$Env:CHEF_LICENSE = "accept-no-persist"

# temp fix until we figure out whats going on in our specific environment as it pertains to unf_ext#
gem install unf_ext -v 0.0.8.2 --source https://rubygems.org/gems/unf_ext

# buildkite changes the casing of the Path variable to PATH
# It is not clear how or where that happens, but it breaks the choco
# tests. Removing the PATH and resetting it with the expected casing
$p = $env:PATH
$env:PATH = $null
$env:Path = $p

# making sure we find the dlls from chef powershell in the tests.
# $powershell_gem_lib = gem which chef-powershell | Select-Object -First 1
# $powershell_gem_path = Split-Path $powershell_gem_lib | Split-Path
# $env:RUBY_DLL_PATH = "$powershell_gem_path/bin/ruby_bin_folder/$env:PROCESSOR_ARCHITECTURE"

# Test PowerShell integration with a simple hello world recipe
Write-Output "Testing PowerShell integration..."
$testRecipe = @'
powershell_script 'test_hello_world' do
  code 'Write-Output "Hello World from PowerShell!"'
  action :run
end
'@

try {
    # Create a temporary recipe file
    $recipeFile = Join-Path $Env:TEMP "test_powershell.rb"
    Set-Content -Path $recipeFile -Value $testRecipe

    Write-Output "Running chef-apply with PowerShell test recipe..."
    chef-apply $recipeFile -l info

    if ($LASTEXITCODE -eq 0) {
        Write-Output "[OK] PowerShell integration test passed!"
    } else {
        Write-Error "[FAIL] PowerShell integration test failed with exit code: $LASTEXITCODE"
        $exit = 1
    }

    # Clean up
    Remove-Item $recipeFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "[FAIL] PowerShell integration test failed with error: $_"
    Write-Error $_.ScriptStackTrace
    $exit = 1
}

If ($exit -ne 0) { Throw $exit }
