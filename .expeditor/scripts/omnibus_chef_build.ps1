#Requires -Version 5.1
<#
  Chef omnibus build, executed inside a Windows Docker container on the Windows agent.

  Credential flow:
    1. pre-command hook (bash on Windows agent): optionally writes AKEYLESS_ACCESS_ID +
       OMNIBUS_DS_PATH to BUILDKITE_ENV_FILE for injection via the Docker plugin.
    2. This script (Initialize-ProgressSigning): uses injected values if present; otherwise
       fetches AKEYLESS_ACCESS_ID from AWS SSM directly (container always has AWS creds).
    3. omnibus-private windows_base.rb: fetches Azure SP creds from Akeyless immediately before
       signing, sets AZURE_* env vars, and signs the MSI via Azure Key Vault.
#>

$ErrorActionPreference = "Stop"

# Source build-settings from omnibus-buildkite-plugin if present (Docker plugin populates this
# from BUILDKITE_ENV_FILE, which includes the Azure credentials written by the pre-command hook)
$buildSettingsPath = "./.omnibus-buildkite-plugin/build-settings.ps1"
if (Test-Path $buildSettingsPath) {
    Write-Output "Sourcing build-settings from omnibus-buildkite-plugin"
    . $buildSettingsPath
}

$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# PATH setup: prepend tools directory (akeyless, dotnet, omnibus toolchain)
# All tools are pre-installed in Docker container (not in default PATH)
$LocalBin = "$env:USERPROFILE\.local\bin"
$env:PATH = "$LocalBin;$env:PATH"
$AkeylessExe = "$LocalBin\akeyless.exe"  # Akeyless CLI for Akeyless secret fetch

# .NET runtime setup: sign.exe (code signing tool) requires DOTNET_ROOT
# Used by omnibus-private windows_base.rb to invoke sign.exe for MSI signing
$DotnetDir = "$env:USERPROFILE\.dotnet"
$env:DOTNET_ROOT = $DotnetDir
$env:PATH = "$DotnetDir\tools;$DotnetDir;$env:PATH"

function Initialize-Environment {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "Setting up environment variables"
        
        # Artifactory configuration: source of gems, pre-built Ruby, omnibus-toolchain
        $env:ARTIFACTORY_BASE_PATH = "com/getchef"
        $env:ARTIFACTORY_ENDPOINT = "https://artifactory-internal.ps.chef.co/artifactory"
        $env:ARTIFACTORY_USERNAME = "buildkite"
        
        # Project configuration for omnibus build
        $env:PROJECT_NAME = "chef"
        $env:OMNIBUS_PIPELINE_DEFINITION_PATH = "${ScriptDir}/../release.omnibus.yml"
        
        # Windows container user paths (Docker container running as ContainerAdministrator)
        $env:HOMEDRIVE = "C:"
        $env:HOMEPATH = "\Users\ContainerAdministrator"
        
        # Omnibus toolchain paths (pre-installed in container)
        # OMNIBUS_TOOLCHAIN_INSTALL_DIR contains: Ruby, gems, embedded SSL certs, native tools
        $env:OMNIBUS_TOOLCHAIN_INSTALL_DIR = "C:\opscode\omnibus-toolchain"
        $env:SSL_CERT_FILE = "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\ssl\certs\cacert.pem"
        
        # MSYS2 configuration (mingw-w64 build environment for native C/C++ gems like libyajl2)
        $env:MSYS2_INSTALL_DIR = "C:\msys64"
        $env:BASH_ENV = "${env:MSYS2_INSTALL_DIR}\etc\bash.bashrc"
        
        # Omnibus architecture target (always x64 on Windows)
        $env:OMNIBUS_WINDOWS_ARCH = "x64"
        
        # MSYSTEM: mingw-w64 variant selection (MINGW64 vs UCRT64 based on Ruby platform)
        # UCRT64 uses Microsoft's Universal CRT (Ruby 3.1+), MINGW64 uses legacy MinGW runtime
        $env:MSYSTEM = "MINGW64"
        $omnibus_toolchain_msystem = & "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin\ruby" -e "puts RUBY_PLATFORM"
        if ($omnibus_toolchain_msystem -eq "x64-mingw-ucrt") {
            $env:MSYSTEM = "UCRT64"
        }
        
        # PATH setup: build tools must be discoverable
        # Order matters: MSYS2 first (bash, sed, awk), then omnibus toolchain (Ruby, gcc), then Windows system tools (WiX, etc.)
        $original_path = $env:PATH
        $env:PATH = "${env:MSYS2_INSTALL_DIR}\$env:MSYSTEM\bin;${env:MSYS2_INSTALL_DIR}\usr\bin;${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin;C:\wix;${original_path}"
        
        Write-Verbose "Environment initialized successfully"
    }
    catch {
        Write-Error "Failed to initialize environment: $_"
        exit 1
    }
}

function Initialize-ProgressSigning {
    [CmdletBinding()]
    param()

    Write-Output "--- Initializing Progress EV code signing"

    # Fetch AKEYLESS_ACCESS_ID from SSM if not already injected via BUILDKITE_ENV_FILE.
    # The container always has AWS credentials (AWS_ACCESS_KEY_ID/SECRET/SESSION_TOKEN).
    if ([string]::IsNullOrWhiteSpace($env:AKEYLESS_ACCESS_ID)) {
        Write-Output "AKEYLESS_ACCESS_ID not in environment; fetching from AWS SSM..."
        $awsRegion = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-west-2" }
        $env:AKEYLESS_ACCESS_ID = (& aws ssm get-parameter `
            --name "buildkite-akeyless-access-id" `
            --with-decryption `
            --region $awsRegion `
            --query "Parameter.Value" `
            --output text 2>&1).Trim()
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($env:AKEYLESS_ACCESS_ID)) {
            throw "Failed to fetch AKEYLESS_ACCESS_ID from Parameter Store (exit $LASTEXITCODE)"
        }
        Write-Output "[OK] AKEYLESS_ACCESS_ID fetched from SSM"
    }

    if ([string]::IsNullOrWhiteSpace($env:OMNIBUS_DS_PATH)) {
        $env:OMNIBUS_DS_PATH = "/DevOps/EvCodeSign/evcodesignservice"
    }
    # Set known akeyless path so windows_base.rb skips discovery
    if ([string]::IsNullOrWhiteSpace($env:AKEYLESS_EXE_PATH)) {
        $env:AKEYLESS_EXE_PATH = "$env:USERPROFILE\.akeyless\bin\akeyless.exe"
    }
    if (-not (Test-Path $env:AKEYLESS_EXE_PATH)) {
        throw "Akeyless CLI not found at: $env:AKEYLESS_EXE_PATH - ensure it is pre-installed in the container image"
    }
    Write-Output "[OK] Akeyless found at: $env:AKEYLESS_EXE_PATH"
    if ([string]::IsNullOrWhiteSpace($env:OMNIBUS_AZURE_KEY_VAULT_URL)) {
        $env:OMNIBUS_AZURE_KEY_VAULT_URL = "https://caps-evcodesign-useast.vault.azure.net"
    }
    if ([string]::IsNullOrWhiteSpace($env:OMNIBUS_AZURE_CERT_NAME)) {
        $env:OMNIBUS_AZURE_CERT_NAME = "psc-evcodesign"
    }

    Write-Output "[OK] Akeyless signing metadata ready; Azure credentials will be fetched by windows_base.rb at signing time"
}

function Sign-ChefPackage {
    [CmdletBinding()]
    param()
    
    Write-Output "--- Verifying Chef MSI signature"

    try {
        # MSI was signed by omnibus-private windows_base.rb during Build-ChefPackage
        $msiPath = Get-ChildItem -Path "C:\omnibus-ruby\chef\pkg\" -Filter "*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1

        if (-not $msiPath) {
            Write-Error "No MSI file found in C:\omnibus-ruby\chef\pkg\"
            exit 1
        }

        $msiPath = $msiPath.FullName
        Write-Output "Found MSI: $(Split-Path $msiPath -Leaf)"

        $sig = Get-AuthenticodeSignature -FilePath $msiPath

        if ($null -eq $sig.SignerCertificate) {
            Write-Error "MSI has no signer certificate (file may be unsigned)"
            exit 1
        }

        Write-Output "  Status:     $($sig.Status)"
        Write-Output "  Subject:    $($sig.SignerCertificate.Subject)"
        Write-Output "  Issuer:     $($sig.SignerCertificate.Issuer)"
        Write-Output "  Thumbprint: $($sig.SignerCertificate.Thumbprint)"

        if ($sig.Status -ne 'Valid') {
            Write-Error "Signature verification failed: $($sig.Status)"
            if ($sig.StatusMessage) { Write-Error "  Details: $($sig.StatusMessage)" }
            exit 1
        }

        Write-Output "[OK] Signature is valid"

        # Subject is the cert holder (Progress Software); Issuer is the CA (GlobalSign)
        if ($sig.SignerCertificate.Issuer -like "*GlobalSign*" -and $sig.SignerCertificate.Subject -like "*PROGRESS*") {
            Write-Output "[OK] Progress EV certificate confirmed"
        } else {
            Write-Warning "Unexpected certificate. Issuer: $($sig.SignerCertificate.Issuer)  Subject: $($sig.SignerCertificate.Subject)"
        }
    }
    catch {
        Write-Error "Failed to verify MSI signature: $_"
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
        
        # Build MSI file URL
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

function Ensure-DotNetRuntime {
    [CmdletBinding()]
    param()

    Write-Output "--- Validating .NET runtime (pre-installed in container/agent)"

    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $dotnetCmd) {
        throw ".NET runtime not found in PATH. Ensure it is pre-installed in the container/agent."
    }

    # sign.exe uses DOTNET_ROOT to locate the runtime
    $env:DOTNET_ROOT = Split-Path -Path $dotnetCmd.Source -Parent
    $version = (dotnet --version 2>&1).Trim()
    Write-Output "[OK] dotnet $version at $env:DOTNET_ROOT"
}

function Install-OmnibusDependencies {
    [CmdletBinding()]
    param()

    try {
        # libyajl2 must be reinstalled to include libyajldll.a for Windows native gem embedding
        Write-Output "--- Removing libyajl2 for reinstall to get libyajldll.a"
        gem uninstall -I libyajl2

        if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
            Write-Error "GITHUB_TOKEN is not set. Cannot access private GitHub dependencies."
            exit 1
        }

        $token = $env:GITHUB_TOKEN.Trim()

        # Write .netrc for git HTTPS auth; restrict to current user and clear token from env
        $netrcPath = "$env:USERPROFILE\_netrc"
        "machine github.com login $token password x-oauth-basic" | Out-File -FilePath $netrcPath -Encoding ascii -Force
        icacls $netrcPath /inheritance:r /grant:r "$($env:USERNAME):(R)"
        Remove-Item Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue

        # Bundler configuration: exclude development dependencies (not needed for build)
        Write-Output "--- Configuring Bundler for private repositories"
        bundle config set --local without development

        # Change to omnibus subdirectory (the omnibus gem submodule)
        Set-Location "$($ScriptDir)/../../omnibus"
        Write-Output "--- Running bundle install for Omnibus"
        bundle install

        # Check if the command succeeded
        if ($LASTEXITCODE -ne 0) {
            throw "bundle install failed with exit code $LASTEXITCODE"
        }

        Write-Output "--- Omnibus dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install Omnibus dependencies: $_"

        # Debug information (directory contents only)
        Write-Output "--- Debug: Current directory contents"
        Get-ChildItem -Force | Select-Object Name, Length

        exit 1
    }
    finally {
        # Clean up .netrc file for security (no longer needed, contains GitHub token)
        $netrcPath = "$env:USERPROFILE\_netrc"
        if (Test-Path $netrcPath) {
            Remove-Item $netrcPath -Force -ErrorAction SilentlyContinue
        }
    }
}
function Build-ChefPackage {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Building Chef"
        
        # Change directory to ensure we're in the right place
        Set-Location "$($ScriptDir)/../../omnibus"
        
        # Set up AWS Region for S3 cache operations
        $AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-west-2" }
        
        # Build options: cache management + logging + AWS S3 integration
        # -l internal: use internal Artifactory for gems/toolchain
        # --populate-s3-cache: cache built packages to S3 for faster rebuilds
        # --log-level debug: detailed logging for troubleshooting
        # AWS overrides: S3 credentials, region, cache naming
        $BUILD_OPTIONS = "-l internal --populate-s3-cache"
        $BUILD_OPTIONS += " --override"
        $BUILD_OPTIONS += " s3_region:$AWS_REGION"
        $BUILD_OPTIONS += " s3_access_key:$($env:AWS_S3_ACCESS_KEY)"
        $BUILD_OPTIONS += " s3_secret_key:$($env:AWS_S3_SECRET_KEY)"
        $BUILD_OPTIONS += " cache_suffix:$($env:PROJECT_NAME)"
        $BUILD_OPTIONS += " append_timestamp:false"
        $BUILD_OPTIONS += " use_git_caching:true"
        $BUILD_OPTIONS += " --log-level debug"
        
        # Set bundle gemfile (bundler needs to know which Gemfile to use)
        $env:BUNDLE_GEMFILE = (Get-Location).Path + "/Gemfile"
        Write-Output "Using Gemfile: $env:BUNDLE_GEMFILE"
        
        Write-Output "Starting omnibus build with options: $BUILD_OPTIONS"
        
        # Split BUILD_OPTIONS into an array for proper argument passing
        $buildArgs = $BUILD_OPTIONS -split ' ' | Where-Object { $_ -ne '' }
        
        # omnibus-private windows_base.rb signs the MSI using AZURE_* env vars during packaging
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

function Upload-BuildkiteArtifact {
    [CmdletBinding()]
    param()
    
    try {
        Write-Output "--- Uploading package to BuildKite"
        C:\buildkite-agent\bin\buildkite-agent.exe artifact upload "C:\omnibus-ruby\chef\pkg\*.msi*" 
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
    Initialize-ProgressSigning
    Initialize-Environment
    Ensure-DotNetRuntime
    
    Install-ChefFoundation
    Install-OmnibusDependencies
    
    Build-ChefPackage
    Sign-ChefPackage
    
    Upload-BuildkiteArtifact
    Publish-ToArtifactory
    
    Write-Output "Chef build and signing completed successfully"
    exit 0
}
catch {
    Write-Error "Chef build pipeline failed: $_"
    exit 1
}
finally {
    # Clear sensitive credentials from the container environment
    Write-Output "--- Cleaning up sensitive environment variables"
    $sensitiveEnvVars = @(
        'AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET',
        'OMNIBUS_AZURE_KEY_VAULT_URL', 'OMNIBUS_AZURE_CERT_NAME',
        'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_SESSION_TOKEN',
        'AWS_S3_ACCESS_KEY', 'AWS_S3_SECRET_KEY',
        'AKEYLESS_ACCESS_ID',
        'ARTIFACTORY_PASSWORD', 'ARTIFACTORY_API_KEY',
        'GITHUB_TOKEN', 'GEM_HOST_API_KEY', 'OMNIBUS_SUBMODULE_CONFIG_PRIVATE'
    )
    foreach ($var in $sensitiveEnvVars) {
        if (Test-Path "env:\$var") { Remove-Item -Path "env:\$var" -ErrorAction SilentlyContinue }
    }
    $netrcPath = "$env:USERPROFILE\_netrc"
    if (Test-Path $netrcPath) { Remove-Item $netrcPath -Force -ErrorAction SilentlyContinue }
    Write-Output "Cleanup complete"
}