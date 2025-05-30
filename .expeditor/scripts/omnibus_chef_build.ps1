$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# to enable smctl debugging with digicert hsm signing un comment:
#
#$env:SM_LOG_LEVEL="TRACE"

if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef-oss" )
{
  Write-Output "--- Generating self-signed Windows package signing certificate"
  $thumb = (New-SelfSignedCertificate -Type Custom -Subject "CN=Chef Software, O=Progress, C=US" -KeyUsage DigitalSignature -FriendlyName "Chef Software Inc." -CertStoreLocation "Cert:\LocalMachine\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")).Thumbprint
}
else
{
  try {
    Write-Output "--- setting up auth for smctl"
    $SM_CLIENT_CERT_FILE_JSON = "sm-client-cert-file.json"
    aws ssm get-parameter --name "sm-client-cert-file" --with-decryption --region "us-west-1" --query Parameter.Value --output text | Set-Content -Path $SM_CLIENT_CERT_FILE_JSON
    # this just grabs the secret as its a json object, converts it, then selects the cert_content_base64, then creates the file to c:\digicert\certificate_pkcs12.p12 while decoding the base64 #
    $smClientCertJson = Get-Content $SM_CLIENT_CERT_FILE_JSON | ConvertFrom-Json | Select-Object -ExpandProperty cert_content_base64
    $decodedFilePath = "c:\digicert\certificate_pkcs12.p12"
    write-output "decoding CLIENT_CERT_FILE_CONTENT c:\digicert\certificate_pkcs12.p12"
    [System.IO.File]::WriteAllBytes($decodedFilePath, [System.Convert]::FromBase64String($smClientCertJson))
  } catch {
      throw $_
  }
  try {
      $file = Get-ChildItem -Path "c:\digicert\certificate_pkcs12.p12"

      if ($file.Length -eq 2902) {
          Write-Output "File attribute length is 2902. Which is correct"
      }
      else {
          write-error "File attribute length is not 2902. Which means it likely failed the previous step at [System.IO.File]::WriteAllBytes!" -ErrorAction Stop
      }
  } catch {
      throw $_
  }

  Write-Output "--- smtcl env settings"
  try {
      $SM_API_KEY_VALUE = aws ssm get-parameter --name "sm-api-key" --with-decryption --region "us-west-1" --query Parameter.Value --output text
      $SM_CLIENT_CERT_PASSWORD_VALUE = aws ssm get-parameter --name "sm-client-cert-password" --with-decryption --region "us-west-1" --query Parameter.Value --output text
      $SM_HOST_VALUE = aws ssm get-parameter --name "sm-host" --with-decryption --region "us-west-1" --query Parameter.Value --output text
      $env:SM_API_KEY_FILE=${SM_API_KEY_VALUE}
      $env:SM_HOST=${SM_HOST_VALUE}
      $env:SM_CLIENT_CERT_FILE="c:\digicert\certificate_pkcs12.p12"
      $env:SM_CLIENT_CERT_PASSWORD_FILE=${SM_CLIENT_CERT_PASSWORD_VALUE}
      smctl credentials save ${SM_API_KEY_VALUE} ${SM_CLIENT_CERT_PASSWORD_VALUE}
  } catch {
    throw $_
  }

####################################################################
write-output "--- smksp_registrar sync certs before chef install"
smksp_registrar.exe register
certutil.exe -csp "DigiCert Software Trust Manager KSP" -key -user
smksp_cert_sync.exe
####################################################################

  try {
    $thumbprint = "7D16AE73AB249D473362E9332D029089DBBB89B2"

    # Get the certificate from the Current User's Personal store by thumbprint, this case its ContainerAdministrator
    $certificate = Get-ChildItem -Path Cert:\CurrentUser\My -Recurse | Where-Object { $_.Thumbprint -eq $thumbprint }

    write-output "--- Display information about the retrieved certificate"
    if ($certificate) {
        Write-Output "Certificate Subject: $($certificate.Subject)"
        Write-Output "Issuer: $($certificate.Issuer)"
        Write-Output "Valid From: $($certificate.NotBefore)"
        Write-Output "Valid To: $($certificate.NotAfter)"
        Write-output "Has Private key: $($certificate.HasPrivateKey)"
        $thumb = $thumbprint  # Set $thumb variable to $thumbprint
    } else {
        Write-Output "Certificate with thumbprint $thumbprint not found. Check SMCTL commands, check to see if the sm_client_cert file is valid, check if the SM_API_KEY hasnt expired, check if SM_CLIENT_CERT_PASSWORD is valid"
    }
    } catch {
      Write-Error $_.Exception.Message
      exit 1
    }
}

$thumb = ${thumbprint}
Write-Output "THUMB=$thumb"

$env:ARTIFACTORY_BASE_PATH="com/getchef"
$env:ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
$env:ARTIFACTORY_USERNAME="buildkite"

Write-Output "--- Installing Chef Foundation ${env:CHEF_FOUNDATION_VERSION}"
. { Invoke-WebRequest -useb https://omnitruck.chef.io/chef/install.ps1 } | Invoke-Expression; install -channel "stable" -project "chef-foundation" -v $env:CHEF_FOUNDATION_VERSION

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

write-output "--- setting critical must have paths for omnibus-toolchain to work"
$original_path = $env:PATH
$env:PATH = "${env:MSYS2_INSTALL_DIR}\$env:MSYSTEM\bin;${env:MSYS2_INSTALL_DIR}\usr\bin;${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin;C:\wix;${original_path}"
Write-Output "env:PATH = $env:PATH"
$env:Path -split ';' | ForEach-Object { $_ }

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

#confirm file is signed
try {
  $directoryPath = "C:\omnibus-ruby\pkg\"
  $msiFile = Get-ChildItem -Path $directoryPath -Filter *.msi | Select-Object -First 1
  write-output "--- test msi path"
  # Check if an .msi file was found
  if ($msiFile -ne $null) {
    # Display the full path of the found .msi file
    $fullPath = $msiFile.FullName
    Write-Output "Found .msi file: $fullPath"

    # Assign the full path to a variable ($fullPath) for later use
    $fullPathVariable = $fullPath
    write-output "--- verify signed file smctl sign verify --input ${fullPathVariable}"
    smctl sign verify --input ${fullPathVariable}
  } else {
    Write-Output "No .msi files found in the directory: $directoryPath or its not signed"
  }
} catch {
  Write-Output "An error occurred: $_"
  exit 1
}

write-output "--- smctl credentials delete just to clean up"
smctl windows certdesync

#uncomment these as well for logs#
# Write-output "--- grabbing smctl logs"
# gc $home\.signingmanager\logs\smctl.log
# gc $home\.signinmanager\logs\smksp.log
# gc $home\.signingmanager\logs\smksp_cert_sync.log

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
