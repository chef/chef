$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef-oss" )
{
  Write-Output "--- Generating self-signed Windows package signing certificate"
  $thumb = (New-SelfSignedCertificate -Type Custom -Subject "CN=Chef Software, O=Progress, C=US" -KeyUsage DigitalSignature -FriendlyName "Chef Software Inc." -CertStoreLocation "Cert:\LocalMachine\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")).Thumbprint
}
else
{
  Write-Output "--- Installing Windows package signing certificate"
  $windows_certificate_json = "windows-package-signing-certificate.json"
  $windows_certificate_pfx = "windows-package-signing-certificate.pfx"

  aws ssm get-parameter --name "windows-package-signing-cert" --with-decryption --region "us-west-1" --query Parameter.Value --output text | Set-Content -Path $windows_certificate_json
  If ($lastexitcode -ne 0) { Throw $lastexitcode }

  $cert_passphrase = Get-Content $windows_certificate_json | ConvertFrom-Json | Select-Object -ExpandProperty cert_passphrase | ConvertTo-SecureString -asplaintext -force
  Get-Content $windows_certificate_json | ConvertFrom-Json | Select-Object -ExpandProperty cert_content_base64 | Set-Content -Path $windows_certificate_pfx
  Remove-Item -Force $windows_certificate_json
  Import-PfxCertificate $windows_certificate_pfx -CertStoreLocation Cert:\LocalMachine\My -Password $cert_passphrase
  Remove-Item -Force $windows_certificate_pfx
  $thumb = "13B510D1CF1B3467856A064F1BEA12D0884D2528"
}

Write-Output "THUMB=$thumb"

$env:ARTIFACTORY_BASE_PATH="com/getchef"
$env:ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
$env:ARTIFACTORY_USERNAME="buildkite"


Write-Output "--- Installing Chef Foundation ${env:CHEF_FOUNDATION_VERSION}"
. { Invoke-WebRequest -useb https://omnitruck.chef.io/chef/install.ps1 } | Invoke-Expression; install -channel "current" -project "chef-foundation" -v ${env:CHEF_FOUNDATION_VERSION}

$env:PROJECT_NAME="chef"
$env:OMNIBUS_PIPELINE_DEFINITION_PATH="${ScriptDir}/../release.omnibus.yml"
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

Write-Output "--- Removing libyajl2 for reinstall to get libyajldll.a"
gem uninstall -I libyajl2

Write-Output "--- Running bundle install for Omnibus"
Set-Location "$($ScriptDir)/../../omnibus"
bundle config set --local without development
bundle install
if ( -not $? ) { throw "Running bundle install failed" }

Write-Output "--- Building Chef"
bundle exec omnibus build chef -l internal --override append_timestamp:false
if ( -not $? ) { throw "omnibus build chef failed" }

Write-Output "--- Uploading package to BuildKite"
C:\buildkite-agent\bin\buildkite-agent.exe artifact upload "pkg/*.msi*"

if ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss" )
{
  Write-Output "--- Setting up Gem API Key"
  $env:GEM_HOST_API_KEY = "Basic ${env:ARTIFACTORY_API_KEY}"

  Write-Output "--- Publishing package to Artifactory"
  bundle exec ruby "${ScriptDir}/omnibus_chef_publish.rb"
  if ( -not $? ) { throw "chef publish failed" }
}
