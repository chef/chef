$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

Write-Output "--- Generating self-signed Windows package signing certificate"
$thumb = (New-SelfSignedCertificate -Type Custom -Subject "CN=Chef Software, O=Progress, C=US" -KeyUsage DigitalSignature -FriendlyName "Chef Software Inc." -CertStoreLocation "Cert:\LocalMachine\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")).Thumbprint

Write-Output "THUMB=$thumb"

$env:ARTIFACTORY_BASE_PATH="com/getchef"
# $env:ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
$env:ARTIFACTORY_USERNAME="buildkite"

Write-Output "--- Install Chef Foundation"
. { Invoke-WebRequest -useb https://omnitruck.chef.io/chef/install.ps1 } | Invoke-Expression; install -channel "current" -project "chef-foundation" -v $CHEF_FOUNDATION_VERSION

$env:PROJECT_NAME="chef"
$env:OMNIBUS_PIPELINE_DEFINITION_PATH="${ScriptDir}/../release.omnibus.yaml"
$env:OMNIBUS_SIGNING_IDENTITY="${thumb}"
$env:HOMEDRIVE = "C:"
$env:HOMEPATH = "\Users\ContainerAdministrator"
$env:OMNIBUS_TOOLCHAIN_INSTALL_DIR = "C:\opscode\omnibus-toolchain"
$env:SSL_CERT_FILE = "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\ssl\certs\cacert.pem"
$env:MSYS2_INSTALL_DIR = "C:\msys64"
$env:BASH_ENV = "${env:MSYS2_INSTALL_DIR}\etc\bash.bashrc"
$env:OMNIBUS_WINDOWS_ARCH = "x64"
$env:MSYSTEM = "MINGW64"
$omnibus_toolchain_msystem = & "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin\ruby" -e "puts RUBY_PLATFORM"
If ($omnibus_toolchain_msystem -eq "x64-mingw-ucrt") {
  $env:MSYSTEM = "UCRT64"
}
$original_path = $env:PATH
$env:PATH = "${env:MSYS2_INSTALL_DIR}\$env:MSYSTEM\bin;${env:MSYS2_INSTALL_DIR}\usr\bin;${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin;C:\wix;C:\Program Files (x86)\Windows Kits\8.1\bin\x64;${original_path}"
Write-Output "env:PATH = $env:PATH"

Write-Output "--- Running bundle install for Omnibus"
Set-Location "$($ScriptDir)/../../omnibus"
bundle config set --local without development
bundle install

Write-Output "--- Building Chef"
bundle exec omnibus build chef -l internal --override append_timestamp:false

