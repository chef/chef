#Requires -Version 5.1

# 
# To enable extra debug messages in the build output, set the environment variable DEBUGSMCTL to true before running the script.
# on the buildkite pipeline env options: DEBUGSMCTL="true" 
# 


[CmdletBinding()]
param()

# Global variables and script-wide error handling
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# Function definitions
function Initialize-Environment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ThumbprintValue
    )
    
    try {
        Write-Output "Setting up environment variables"
        
        $env:ARTIFACTORY_BASE_PATH = "com/getchef"
        $env:ARTIFACTORY_ENDPOINT = "https://artifactory-internal.ps.chef.co/artifactory"
        $env:ARTIFACTORY_USERNAME = "buildkite"
        
        $env:PROJECT_NAME = "chef"
        $env:OMNIBUS_PIPELINE_DEFINITION_PATH = "${ScriptDir}/../release.omnibus.yml"
        $env:OMNIBUS_SIGNING_IDENTITY = "${ThumbprintValue}"
        $env:HOMEDRIVE = "C:"
        $env:HOMEPATH = "\Users\ContainerAdministrator"
        $env:OMNIBUS_TOOLCHAIN_INSTALL_DIR = "C:\opscode\omnibus-toolchain"
        $env:SSL_CERT_FILE = "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\ssl\certs\cacert.pem"
        $env:MSYS2_INSTALL_DIR = "C:\msys64"
        $env:BASH_ENV = "${env:MSYS2_INSTALL_DIR}\etc\bash.bashrc"
        $env:OMNIBUS_WINDOWS_ARCH = "x64"
        
        # Configure MSYSTEM based on Ruby platform
        $env:MSYSTEM = "MINGW64"
        $omnibus_toolchain_msystem = & "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin\ruby" -e "puts RUBY_PLATFORM"
        if ( -not $? ) { throw "Failed to determine Ruby platform" }
        
        if ($omnibus_toolchain_msystem -eq "x64-mingw-ucrt") {
            $env:MSYSTEM = "UCRT64"
        }
        
        # Set PATH
        $original_path = $env:PATH
        $env:PATH = "${env:MSYS2_INSTALL_DIR}\$env:MSYSTEM\bin;${env:MSYS2_INSTALL_DIR}\usr\bin;${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin;C:\wix;${original_path}"
        Write-Output "PATH = $env:PATH"
        $env:Path -split ';' | ForEach-Object { $_ }
        
        Write-Verbose "Environment initialized successfully"
    }
    catch {
        Write-Error "Failed to initialize environment: $_"
        exit 1
    }
}

function Set-SelfSignedCertificate {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Generating self-signed Windows package signing certificate"
        $thumbprint = (New-SelfSignedCertificate -Type Custom -Subject "CN=Chef Software, O=Progress, C=US" -KeyUsage DigitalSignature -FriendlyName "Chef Software Inc." -CertStoreLocation "Cert:\LocalMachine\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")).Thumbprint
        if ( -not $? ) { throw "Failed to generate self-signed certificate" }
        
        return $thumbprint
    }
    catch {
        Write-Error "Failed to set up self-signed certificate: $_"
        exit 1
    }
}

function Get-SmctlCertificate {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- setting up auth for smctl"
        $SM_CLIENT_CERT_FILE_JSON = "sm-client-cert-file.json"
        aws ssm get-parameter --name "sm-client-cert-file" --with-decryption --region "us-west-1" --query Parameter.Value --output text | Set-Content -Path $SM_CLIENT_CERT_FILE_JSON
        if ( -not $? ) { throw "Failed to get sm-client-cert-file parameter" }
        
        # Process the JSON certificate content
        $smClientCertJson = Get-Content $SM_CLIENT_CERT_FILE_JSON | ConvertFrom-Json | Select-Object -ExpandProperty cert_content_base64
        if ( -not $? ) { throw "Failed to parse sm-client-cert-file JSON" }
        
        $decodedFilePath = "c:\digicert\certificate_pkcs12.p12"
        Write-Output "Decoding certificate content to $decodedFilePath"
        [System.IO.File]::WriteAllBytes($decodedFilePath, [System.Convert]::FromBase64String($smClientCertJson))
        if ( -not $? ) { throw "Failed to write certificate file" }
        
        # Verify the certificate file
        $file = Get-ChildItem -Path "c:\digicert\certificate_pkcs12.p12"
        if ( -not $? ) { throw "Failed to get certificate file" }

        if ($file.Length -eq 2902) {
            Write-Output "Certificate file verified (length = 2902 bytes)"
        }
        else {
            throw "Certificate file has incorrect length: $($file.Length) bytes"
        }
    }
    catch {
        Write-Error "Failed to get smctl certificate: $_"
        exit 1
    }
}

function Set-SmctlCredentials {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- smtcl env settings"
        $SM_API_KEY_VALUE = aws ssm get-parameter --name "sm-api-key" --with-decryption --region "us-west-1" --query Parameter.Value --output text
        if ( -not $? ) { throw "Failed to get sm-api-key parameter" }
        
        $SM_CLIENT_CERT_PASSWORD_VALUE = aws ssm get-parameter --name "sm-client-cert-password" --with-decryption --region "us-west-1" --query Parameter.Value --output text
        if ( -not $? ) { throw "Failed to get sm-client-cert-password parameter" }
        
        $SM_HOST_VALUE = aws ssm get-parameter --name "sm-host" --with-decryption --region "us-west-1" --query Parameter.Value --output text
        if ( -not $? ) { throw "Failed to get sm-host parameter" }
        
        $env:SM_API_KEY_FILE = ${SM_API_KEY_VALUE}
        $env:SM_HOST = ${SM_HOST_VALUE}
        $env:SM_CLIENT_CERT_FILE = "c:\digicert\certificate_pkcs12.p12"
        $env:SM_CLIENT_CERT_PASSWORD_FILE = ${SM_CLIENT_CERT_PASSWORD_VALUE}
        
        smctl credentials save ${SM_API_KEY_VALUE} ${SM_CLIENT_CERT_PASSWORD_VALUE}
        if ( -not $? ) { throw "Failed to save smctl credentials" }
    }
    catch {
        Write-Error "Failed to set smctl credentials: $_"
        exit 1
    }
}

function Register-SmctlCertificates {
    [CmdletBinding()]
    param()
    
    try {
        if ($env:DEBUGSMCTL -eq $true) {
            Write-Output "--- Debug SMCTLCert registration is enabled, adding some additional testing output"
            smksp_registrar.exe list
            smksp_registrar.exe remove
            if ( -not $? ) { throw "Failed to remove DigiCert Signing Manager and Trust Manager KSP" }
            smksp_registrar.exe list

            Write-Output "--- smksp_registrar sync certs before chef install"
            smksp_registrar.exe register
            if ( -not $? ) { throw "Failed to register certificates" }
            smksp_registrar.exe list
            if ( -not $? ) { throw "Failed to register certificates" }

            Write-Output "--- Get Healthcheck Status"
            smctl healthcheck
            if ( -not $? ) { throw "Failed to get smctl healthcheck status" }

            Write-Output "--- get SMCTL logs"
            get-content C:\Users\$env:USERNAME\.signingmanager\logs\smctl.log
            if (-not $?) { throw "Failed to get SMCTL logs" }
        }
        else {
            Write-Output "--- smksp_registrar unregister first"
            smksp_registrar.exe remove
            if ( -not $? ) { throw "Failed to remove DigiCert Signing Manager and Trust Manager KSP" }
            
            Write-Output "--- smksp_registrar sync certs before chef install"
            smksp_registrar.exe register
            if ( -not $? ) { throw "Failed to register certificates" }
    
            Write-Output "--- Installing Windows package signing certificate using smctl cli"
            smctl windows certsync --keypair-alias=key_1340572417
            if ( -not $? ) { throw "Failed to sync certificates using smctl" }   
        }
    }
    catch {
        Write-Error "Failed to register smctl certificates: $_"
        exit 1
    }
}

function Smctl-Debug {
    [CmdletBinding()]
    param()
    try {
        if ($env:DEBUGSMCTL -eq $true) {
            Write-Output "--- Setting SM_LOG_LEVEL to TRACE as DEBUGSMCTL is true"        
            $env:SM_LOG_LEVEL="TRACE"
            if (-not $?) { throw "Failed to set SM_LOG_LEVEL" }
        }
    }
    catch {
        Write-Error "--- Failed to set SM_LOG_LEVEL: $_"
    }    
}

function Get-Certificate {
    [CmdletBinding()]
    param()
    
    try {
        $thumbprint = "33A82DC08CA7C6B370FFD0C958D9EE30187DE9E4"

        # List all certificate from the Current User's Personal store by thumbprint
        $certificate = Get-ChildItem -Path Cert:\CurrentUser\My -Recurse | Where-Object { $_.Thumbprint -eq $thumbprint }
        if ( -not $? ) { throw "Failed to retrieve certificates" }

        Write-Host "--- Display information about the retrieved certificate"
        
        if ($certificate) {
            Write-Host "Certificate Subject: $($certificate.Subject)"
            Write-Host "Issuer: $($certificate.Issuer)"
            Write-Host "Valid From: $($certificate.NotBefore)"
            Write-Host "Valid To: $($certificate.NotAfter)"
            Write-Host "Has Private key: $($certificate.HasPrivateKey)"
            
            # Return only the thumbprint string, not the Write-Output results
            return $thumbprint.ToString()
        } else {
            throw "Certificate with thumbprint $thumbprint not found"
        }
    }
    catch {
        Write-Error "Failed to get certificate: $_"
        exit 1
    }
}

function Install-ChefFoundation {
    [CmdletBinding()]
    param(
      # this is to pass into the msiURL, for now its static, but if we want to change it in the future for a different version we can.
        [string]$Version = $env:CHEF_FOUNDATION_VERSION,
        [string]$WindowsVersion = "2022",
        [string]$Architecture = "x64"
    )
    
    try {
        Write-Output "--- Installing Chef Foundation ${Version}"
        
        # Create temp directory if it doesn't exist
        $tempDir = Join-Path $env:TEMP "chef-foundation"
        if (-not (Test-Path $tempDir)) {
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        }
        
        # Build MSI file URL and stops using old api and goes direct to packages.
        $msiUrl = "https://packages.chef.io/files/stable/chef-foundation/${Version}/windows/${WindowsVersion}/chef-foundation-${Version}-1-${Architecture}.msi"
        $msiFile = Join-Path $tempDir "chef-foundation-$Version.msi"
        
        Write-Output "Downloading from $msiUrl to $msiFile"
        
        # Download the MSI
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiFile -UseBasicParsing
        if (-not $?) { 
            throw "Failed to download Chef Foundation MSI from $msiUrl" 
        }
        
        # Verify file was downloaded and has content
        if (-not (Test-Path $msiFile) -or (Get-Item $msiFile).Length -eq 0) {
            throw "Downloaded MSI file is missing or empty: $msiFile"
        }
        
        Write-Output "Installing MSI: $msiFile"
        
        # Install the MSI quietly
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /i `"$msiFile`"" -Passthru -Wait -NoNewWindow
        
        # Check installation result
        if ($p.ExitCode -eq 1618) {
            Write-Warning "Another MSI installation is in progress (exit code 1618), installation might be incomplete"
        } 
        elseif ($p.ExitCode -ne 0) {
            throw "MSI installation failed with exit code $($p.ExitCode)"
        }
        
        Write-Output "Chef Foundation $Version installed successfully"
        
        # Optional: Clean up the downloaded MSI
        Remove-Item -Path $msiFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to install Chef Foundation: $_"
        exit 1
    }
}

function Install-OmnibusDependencies {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Removing libyajl2 for reinstall to get libyajldll.a"
        gem uninstall -I libyajl2
        
        Write-Output "--- Running bundle install for Omnibus"
        Set-Location "$($ScriptDir)/../../omnibus"
        bundle config set --local without development
        bundle install
        if ( -not $? ) { throw "Running bundle install failed" }
    }
    catch {
        Write-Error "Failed to install Omnibus dependencies: $_"
        exit 1
    }
}

function Build-ChefPackage {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Building Chef"
        
        # Change directory to ensure we're in the right place
        Set-Location "$($ScriptDir)/../../omnibus"
        
        # Set up AWS Region
        $AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-west-2" }
        
        # Set up build options similar to omnibus-buildkite-plugin
        $BUILD_OPTIONS = "-l internal --populate-s3-cache"
        $BUILD_OPTIONS += " --override"
        $BUILD_OPTIONS += " s3_region:$AWS_REGION"
        $BUILD_OPTIONS += " s3_access_key:$($env:AWS_S3_ACCESS_KEY)"
        $BUILD_OPTIONS += " s3_secret_key:$($env:AWS_S3_SECRET_KEY)"
        $BUILD_OPTIONS += " cache_suffix:$($env:PROJECT_NAME)"
        $BUILD_OPTIONS += " append_timestamp:false"
        $BUILD_OPTIONS += " use_git_caching:true"
        $BUILD_OPTIONS += " --log-level debug"
        
        # Set bundle gemfile
        $env:BUNDLE_GEMFILE = (Get-Location).Path + "/Gemfile"
        Write-Output "Using Gemfile: $env:BUNDLE_GEMFILE"
        
        Write-Output "Starting omnibus build with options: $BUILD_OPTIONS"
        
        # Split BUILD_OPTIONS into an array for proper argument passing
        $buildArgs = $BUILD_OPTIONS -split ' ' | Where-Object { $_ -ne '' }
        
        # Execute the build command
        & bundle exec omnibus build $env:PROJECT_NAME @buildArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Omnibus build failed with exit code $LASTEXITCODE"
        }
        
        Write-Output "Omnibus build completed successfully"
    }
    catch {
        Write-Error "Chef build failed: $_"
        
        # Try to get more detailed logs
        Write-Output "--- Attempting to collect detailed build logs"
        Get-ChildItem "C:\omnibus-ruby\log\" -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*build*.log" } | 
            ForEach-Object {
                Write-Output "=== Log file: $($_.FullName) ==="
                Get-Content $_.FullName -Tail 200
            }
            
        throw "Chef build failed. See logs for details."
    }
}

function Verify-SignedPackage {
    [CmdletBinding()]
    param()
    
    $verificationFailed = $false
    $errorMessage = ""
    
    try {
        # Fix: Add the missing 'chef' subdirectory to the path
        $directoryPath = "C:\omnibus-ruby\chef\pkg\"
        $msiFile = Get-ChildItem -Path $directoryPath -Filter *.msi | Select-Object -First 1
        if ( -not $? ) { throw "Failed to list MSI files" }
        
        Write-Output "--- test msi path"
        
        # Check if an .msi file was found
        if ($msiFile -ne $null) {
            # Display the full path of the found .msi file
            $fullPath = $msiFile.FullName
            Write-Output "Found .msi file: $fullPath"
            # check with signtool for additional verification
            Write-Output "--- verify signed file using signtool"
            $signToolOutput = signtool verify /pa $fullPath 2>&1 | Out-String
            
            if ($LASTEXITCODE -ne 0) {
                $verificationFailed = $true
                $errorMessage = "signtool verification failed: $signToolOutput"
            }
            
            if (-not $verificationFailed) {
                Write-Output "MSI signing verification passed"
            }
        } else {
            $verificationFailed = $true
            $errorMessage = "No .msi files found in the directory: $directoryPath"
        }
    }
    catch {
        $verificationFailed = $true
        $errorMessage = "Package verification failed: $_"
    }
    
    # Always attempt to display logs regardless of verification result
    try {
        if ($env:DEBUGSMCTL -eq $true) {
            Write-Output "--- grabbing smctl logs"
            Get-Content $home\.signingmanager\logs\smctl.log -ErrorAction SilentlyContinue
            Get-Content $home\.signingmanager\logs\smksp.log -ErrorAction SilentlyContinue
            Get-Content $home\.signingmanager\logs\smksp_cert_sync.log -ErrorAction SilentlyContinue
            Write-Host "--- list all keys available to the current user"
            certutil.exe -csp "DigiCert Software Trust Manager KSP" -key -user
        }
    }
    catch {
        Write-Error "--- All smctl logs not found, please check smctl configuration"
    }
    
    # Now handle the verification failure if it occurred
    if ($verificationFailed) {
        Write-Error $errorMessage
        exit 1
    }
}

function Cleanup-SmctlCredentials {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- smctl credentials delete just to clean up"
        smctl windows certdesync
        if ( -not $? ) { throw "Failed to clean up smctl credentials" }
        
    }
    catch {
        Write-Error "Failed to clean up smctl credentials: $_"
        # Not exiting with code 1 as this is a cleanup step
        Write-Warning "Continuing despite credential cleanup failure"
    }
}

function Upload-BuildkiteArtifact {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Uploading package to BuildKite"
        # Fix: Update the path to include the chef subdirectory
        C:\buildkite-agent\bin\buildkite-agent.exe artifact upload "omnibus/pkg/*.msi*"
        if ( -not $? ) { throw "Failed to upload artifact to BuildKite" }
    }
    catch {
        Write-Error "Failed to upload artifact: $_"
        exit 1
    }
}

function Publish-ToArtifactory {
    [CmdletBinding()]
    param()
    
    try {
        if ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss") {
            Write-Output "--- Setting up Gem API Key"
            $env:GEM_HOST_API_KEY = "Basic ${env:ARTIFACTORY_API_KEY}"

            Write-Output "--- Publishing package to Artifactory"
            bundle exec ruby "${ScriptDir}/omnibus_chef_publish.rb"
            if ( -not $? ) { throw "Chef publish failed" }
        }
        else {
            Write-Output "--- Skipping Artifactory publish for chef-oss organization"
        }
    }
    catch {
        Write-Error "Failed to publish to Artifactory: $_"
        exit 1
    }
}

# Main execution block
try {
    # Determine certificate to use based on organization
    if ($env:BUILDKITE_ORGANIZATION_SLUG -eq "chef-oss") {
        $thumbprint = Set-SelfSignedCertificate
    }
    else {
        # DigiCert setup
        Get-SmctlCertificate
        Set-SmctlCredentials
        Register-SmctlCertificates
        $thumbprint = Get-Certificate
    }
    
    # Make sure thumbprint is a clean string
    $thumbprint = $thumbprint.Trim()
    
    Write-Output "THUMB=$thumbprint"
    
    # Set up the build environment
    Initialize-Environment -ThumbprintValue $thumbprint
    Smctl-Debug
    Install-ChefFoundation
    Install-OmnibusDependencies
    
    # Build and verify package
    Build-ChefPackage
    Verify-SignedPackage
    
    # Cleanup and publish
    Cleanup-SmctlCredentials
    Upload-BuildkiteArtifact
    Publish-ToArtifactory
    
    Write-Output "Chef build and publish completed successfully"
    exit 0
}
catch {
    Write-Error "Chef build pipeline failed: $_"
    exit 1
}
