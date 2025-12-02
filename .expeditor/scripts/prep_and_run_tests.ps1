param(
    # The test type ot be run (unit, integration or functional)
    [Parameter(Position=0)][String]$TestType
)

# $env:Path = 'C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\;C:\ProgramData\chocolatey\bin;C:\Program Files (x86)\Windows Kits\8.1\Windows Performance Toolkit\;C:\Program Files\Git\cmd;C:\Users\ContainerAdministrator\AppData\Local\Microsoft\WindowsApps;' + $env:Path

if ($TestType -eq 'Functional') {
    winrm quickconfig -q
}

powershell -File "./.expeditor/scripts/ensure-minimum-viable-hab.ps1"
if (-not $?) { throw "Could not ensure the minimum hab version required is installed." }
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "C:\hab\bin;" + $env:Path # add hab bin path for binlinking
$env:HAB_LICENSE = "accept-no-persist"

Write-Output "--- Checking the Chocolatey version"
$installed_version = Get-ItemProperty "${env:ChocolateyInstall}/choco.exe" | select-object -expandproperty versioninfo| select-object -expandproperty productversion
if(-not ($installed_version -match ('^2'))){
    Write-Output "--- Now Upgrading Choco"
    try {
        choco feature enable -n=allowGlobalConfirmation
        choco upgrade chocolatey
    }
    catch {
        Write-Output "Upgrade Failed"
        Write-Output $_
        <#Do this if a terminating exception happens#>
    }
}

Write-Output "--- Installing core/ruby3_4-plus-devkit via Habitat"
hab pkg install core/ruby3_4-plus-devkit --channel base-2025 --binlink --force
if (-not $?) { throw "Could not install ruby with devkit via Habitat." }
$ruby_dir = & hab pkg path core/ruby3_4-plus-devkit

Write-Output "--- Installing OpenSSL via Habitat"
hab pkg install core/openssl/3.5.0 --channel base-2025 --binlink --force
if (-not $?) { throw "Could not install OpenSSL via Habitat." }

# Set $openssl_dir to Habitat OpenSSL package installation path
$openssl_dir = & hab pkg path core/openssl/3.5.0
if (-not $openssl_dir) { throw "Could not determine core/openssl installation directory." }

hab pkg install core/cacerts --channel base-2025
$cacerts_dir = & hab pkg path core/cacerts
if (-not $cacerts_dir) { throw "Could not determine core/cacerts installation directory." }
# Set the env variables for OpenSSL
$env:SSL_CERT_FILE = "$cacerts_dir\ssl\certs\cacert.pem"
$env:RUBY_DLL_PATH = "$openssl_dir\bin"
$env:OPENSSL_CONF = "$openssl_dir\ssl\openssl.cnf"
$env:OPENSSL_ROOT_DIR = $openssl_dir
$env:OPENSSL_INCLUDE_DIR = "$openssl_dir\include"
$env:OPENSSL_LIB_DIR = "$openssl_dir\lib"

$env:Path = "$openssl_dir\bin;$ruby_dir\bin;" + $env:Path

Write-Output "Configure bundle to build openssl gem with $openssl_dir"
bundle config build.openssl --with-openssl-dir=$openssl_dir
gem install openssl:3.3.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir\include" --with-openssl-lib="$openssl_dir\lib"

Write-Output "OpenSSL directory: $openssl_dir"
Write-Output "PATH: $env:Path"
Write-Output "SSL_CERT_FILE: $env:SSL_CERT_FILE"
Write-Output "RUBY_DLL_PATH: $env:RUBY_DLL_PATH"

Write-Output "--- Checking ruby, bundle, gem and openssl paths"
(Get-Command ruby).Source
(Get-Command bundle).Source
(Get-Command gem).Source
(Get-Command openssl).Source

Write-Output "--- Does ruby have openssl access?"
ruby -e "require 'openssl'; puts 'OpenSSL loaded successfully: ' + OpenSSL::OPENSSL_VERSION; puts 'OpenSSL gem version: ' + OpenSSL::VERSION;"

Write-Output "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3

Write-Output "--- Locating chef-powershell-shim"
$chef_powershell_gem_path = bundle info chef-powershell --path
if (-not $?) {
    Write-Error "Could not locate chef-powershell gem."
    exit 1
}
$chef_powershell_gem_path = $chef_powershell_gem_path.Trim()
$shim_repo_path = Split-Path -Path $chef_powershell_gem_path -Parent
Write-Output "chef-powershell-shim repo located at: $shim_repo_path"

if (-not (Test-Path (Join-Path $shim_repo_path "habitat"))) {
    Write-Error "Could not find habitat directory in $shim_repo_path. Is the gem structure correct?"
    exit 1
}

# Copy to a temporary directory with a short path to avoid Windows path length issues in Habitat Studio
$build_dir = "C:\cps-build"
if (Test-Path $build_dir) {
    Remove-Item $build_dir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $build_dir | Out-Null
Write-Output "--- Copying chef-powershell-shim to $build_dir for build"
Copy-Item "$shim_repo_path\*" $build_dir -Recurse -Force

Push-Location $build_dir

Write-Output "--- Building chef-powershell-shim via Habitat"
Write-Output "--- Generating temporary 'chef' origin key for signing"
hab origin key generate chef
if (-not $?) { throw "Could not generate habitat key for chef origin." }

$env:HAB_ORIGIN = "chef"
hab pkg build habitat
if (-not $?) { throw "Could not build chef-powershell-shim via Habitat." }

$last_build_env = Get-Content "results/last_build.env" | ConvertFrom-StringData
$pkg_ident = $last_build_env.pkg_ident
$pkg_artifact = $last_build_env.pkg_artifact

Write-Output "--- Installing chef-powershell-shim package"
hab pkg install "results/$pkg_artifact"
if (-not $?) { throw "Could not install chef-powershell-shim package." }

$pkg_path = hab pkg path $pkg_ident
$arch = $env:PROCESSOR_ARCHITECTURE
if (-not $arch) { $arch = "AMD64" }

# Copy DLLs to the bundler gem path so tests can use them
$dll_target_bundler = Join-Path $chef_powershell_gem_path "bin/ruby_bin_folder/$arch"
if (-not (Test-Path $dll_target_bundler)) {
    New-Item -ItemType Directory -Force -Path $dll_target_bundler
}
Write-Output "--- Copying DLLs from $pkg_path/bin to $dll_target_bundler"
Copy-Item "$pkg_path/bin/*" $dll_target_bundler -Recurse -Force

# Also copy to the build dir to build the gem
$dll_target_build = Join-Path $build_dir "chef-powershell/bin/ruby_bin_folder/$arch"
if (-not (Test-Path $dll_target_build)) {
    New-Item -ItemType Directory -Force -Path $dll_target_build
}
Write-Output "--- Copying DLLs from $pkg_path/bin to $dll_target_build"
Copy-Item "$pkg_path/bin/*" $dll_target_build -Recurse -Force

Write-Output "--- Building chef-powershell gem"
Push-Location chef-powershell
gem build chef-powershell.gemspec
if (-not $?) { throw "Could not build chef-powershell gem." }

$gem_file = Get-ChildItem chef-powershell-*.gem | Sort-Object LastWriteTime | Select-Object -Last 1
Write-Output "--- Installing chef-powershell gem: $gem_file"
gem install $gem_file --verbose
if (-not $?) { throw "Could not install chef-powershell gem." }

Pop-Location # chef-powershell
Pop-Location # build_dir

switch ($TestType) {
    "Unit"          {[string[]]$RakeTest = 'spec:unit','component_specs'; break}
    "Integration"   {[string[]]$RakeTest = "spec:integration"; break}
    "Functional"    {[string[]]$RakeTest = "spec:functional"; break}
    default         {throw "TestType $TestType not valid"}
}

foreach($test in $RakeTest) {
    Write-Output "--- Chef $test run"
    bundle exec rake $test
    if (-not $?) { throw "Chef $test tests failed" }
}
