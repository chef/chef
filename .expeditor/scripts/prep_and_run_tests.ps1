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

# making sure we find the dlls from chef powershell
$powershell_gem_lib = gem which chef-powershell | Select-Object -First 1
$powershell_gem_path = Split-Path $powershell_gem_lib | Split-Path
$env:RUBY_DLL_PATH = "$powershell_gem_path/bin/ruby_bin_folder/$env:PROCESSOR_ARCHITECTURE"

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
