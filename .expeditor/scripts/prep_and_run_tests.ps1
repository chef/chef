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

Write-Output "--- Installing chef/ruby31-plus-devkit/3.1.6 via Habitat"
hab pkg install chef/ruby31-plus-devkit/3.1.6 --channel LTS-2024 --binlink --force
if (-not $?) { throw "Could not install ruby with devkit via Habitat." }
$ruby_dir = & hab pkg path chef/ruby31-plus-devkit/3.1.6

Write-Output "--- Installing OpenSSL via Habitat"
hab pkg install core/openssl/3.0.9 --channel LTS-2024 --binlink --force
if (-not $?) { throw "Could not install OpenSSL via Habitat." }

# Set $openssl_dir to Habitat OpenSSL package installation path
$openssl_dir = & hab pkg path core/openssl/3.0.9
if (-not $openssl_dir) { throw "Could not determine core/openssl installation directory." }

hab pkg install core/cacerts --channel LTS-2024
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
gem install openssl:3.2.0 -- --with-openssl-dir=$openssl_dir --with-openssl-include="$openssl_dir\include" --with-openssl-lib="$openssl_dir\lib"

Write-Output "OpenSSL directory: $openssl_dir"
Write-Output "PATH: $env:Path"
Write-Output "SSL_CERT_FILE: $env:SSL_CERT_FILE"
Write-Output "RUBY_DLL_PATH: $env:RUBY_DLL_PATH"

Write-Output "ssl_env_hack.rb"
# Path to the ssl_env_hack.rb file
$sslEnvHackPath = "omnibus/files/openssl-customization/windows/ssl_env_hack.rb"
$hackContent = Get-Content $sslEnvHackPath -Raw

# Find all openssl.rb files in $env:GEM_HOME/**/openssl-*/lib/openssl.rb
$opensslFiles = Get-ChildItem -Path "$env:GEM_HOME" -Recurse -Filter "openssl.rb" | Where-Object {
  $_.FullName -match "openssl-[^\\\/]+[\\\/]lib[\\\/]openssl\.rb$"
}

foreach ($file in $opensslFiles) {
  $originalContent = Get-Content $file.FullName -Raw
  if ($originalContent -notlike "*$hackContent*") {
    Set-Content $file.FullName -Value "$hackContent`r`n$originalContent"
  }
}

Write-Output "--- Checking ruby, bundle, gem and openssl paths"
(Get-Command ruby).Source
(Get-Command bundle).Source
(Get-Command gem).Source
(Get-Command openssl).Source

Write-Output "--- Does ruby have openssl access?"
ruby -e "require 'openssl'; puts 'OpenSSL loaded successfully: ' + OpenSSL::OPENSSL_VERSION; puts 'OpenSSL gem version: ' + OpenSSL::VERSION;"

Write-Output "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3

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
