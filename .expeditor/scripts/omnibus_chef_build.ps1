#Requires -Version 5.1

<#
  Chef omnibus build, executed inside a Windows Docker container on the
  Windows 2019 Buildkite agent.

  Chef-18 uses a hybrid build architecture:

      Windows 2019 Buildkite host
          |
          +-- Docker
                |
                +-- Windows build container
                      |
                      +-- Omnibus
                            |
                            +-- omnibus-private/windows_base.rb
                                  |
                                  +-- Akeyless
                                        |
                                        +-- Azure Key Vault signing

  Credential flow:

    1. Buildkite pre-command runs on the Windows host.
    2. pre-command retrieves:
         - AKEYLESS_ACCESS_ID
         - OMNIBUS_DS_PATH
         - OMNIBUS_AZURE_KEY_VAULT_URL
         - OMNIBUS_AZURE_CERT_NAME
       from AWS Parameter Store.
    3. Docker plugin propagates those environment variables into this container.
    4. This script validates that the signing metadata exists.
    5. Chef is built normally.
    6. windows_base.rb authenticates to Akeyless immediately before signing.
    7. windows_base.rb retrieves the short-lived Azure credentials.
    8. Azure credentials are placed into the Ruby process environment only for signing.
    9. MSI is signed using Azure Key Vault.
   10. Azure credentials are removed immediately after signing.
   11. MSI signature is independently verified.
   12. Sensitive environment variables are removed during final cleanup.

  IMPORTANT:
    Azure tenant/client/secret are NEVER fetched by this script and are NEVER
    printed to Buildkite logs.
#>

$ErrorActionPreference = "Stop"

# Source build-settings from omnibus-buildkite-plugin if present.
# Chef-18 normally does not use the plugin, but preserve compatibility.
$buildSettingsPath = "./.omnibus-buildkite-plugin/build-settings.ps1"

if (Test-Path $buildSettingsPath) {
    Write-Output "Sourcing build-settings from omnibus-buildkite-plugin"
    . $buildSettingsPath
}

$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

# ---------------------------------------------------------------------------
# PATH setup
# ---------------------------------------------------------------------------

$LocalBin = "$env:USERPROFILE\.local\bin"

$env:PATH = "$LocalBin;$env:PATH"

$AkeylessExe = "$LocalBin\akeyless.exe"

# .NET runtime setup.
$DotnetDir = "$env:USERPROFILE\.dotnet"

$env:DOTNET_ROOT = $DotnetDir
$env:PATH = "$DotnetDir\tools;$DotnetDir;$env:PATH"


function Initialize-Environment {
    [CmdletBinding()]
    param()

    try {
        Write-Output "--- Initializing Chef build environment"

        # Artifactory configuration
        $env:ARTIFACTORY_BASE_PATH = "com/getchef"
        $env:ARTIFACTORY_ENDPOINT = "https://artifactory-internal.ps.chef.co/artifactory"
        $env:ARTIFACTORY_USERNAME = "buildkite"

        # Project configuration
        $env:PROJECT_NAME = "chef"
        $env:OMNIBUS_PIPELINE_DEFINITION_PATH = "${ScriptDir}/../release.omnibus.yml"

        # Windows container user paths
        $env:HOMEDRIVE = "C:"
        $env:HOMEPATH = "\Users\ContainerAdministrator"

        # Omnibus toolchain
        $env:OMNIBUS_TOOLCHAIN_INSTALL_DIR = "C:\opscode\omnibus-toolchain"
        $env:SSL_CERT_FILE = "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\ssl\certs\cacert.pem"

        # MSYS2
        $env:MSYS2_INSTALL_DIR = "C:\msys64"
        $env:BASH_ENV = "${env:MSYS2_INSTALL_DIR}\etc\bash.bashrc"

        # Omnibus architecture
        $env:OMNIBUS_WINDOWS_ARCH = "x64"

        # Determine MSYSTEM from Ruby platform.
        $env:MSYSTEM = "MINGW64"

        $omnibus_toolchain_msystem = & `
            "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin\ruby" `
            -e "puts RUBY_PLATFORM"

        if ($omnibus_toolchain_msystem -eq "x64-mingw-ucrt") {
            $env:MSYSTEM = "UCRT64"
        }

        # Build tools must be discoverable.
        $original_path = $env:PATH

        $env:PATH = `
            "${env:MSYS2_INSTALL_DIR}\$env:MSYSTEM\bin;" +
            "${env:MSYS2_INSTALL_DIR}\usr\bin;" +
            "${env:OMNIBUS_TOOLCHAIN_INSTALL_DIR}\embedded\bin;" +
            "C:\wix;" +
            "${original_path}"

        Write-Output "[OK] Build environment initialized"
    }
    catch {
        Write-Error "Failed to initialize environment: $_"
        throw
    }
}


function Initialize-ProgressSigning {
    [CmdletBinding()]
    param()

    Write-Output "--- Initializing Progress EV code signing"

    # AKEYLESS_ACCESS_ID is injected by the Buildkite pre-command hook.
    if ([string]::IsNullOrWhiteSpace($env:AKEYLESS_ACCESS_ID)) {
        throw "AKEYLESS_ACCESS_ID not set. Expected it from .buildkite/hooks/pre-command."
    }

    # Use the pre-installed Akeyless CLI.
    #
    # Keep this deterministic rather than performing discovery during signing.
    $candidatePaths = @(
        "$env:USERPROFILE\.local\bin\akeyless.exe",
        "$env:USERPROFILE\.akeyless\bin\akeyless.exe"
    )

    $AkeylessPath = $null

    foreach ($candidate in $candidatePaths) {
        if (Test-Path $candidate) {
            $AkeylessPath = $candidate
            break
        }
    }

    if (-not $AkeylessPath) {
        $command = Get-Command akeyless.exe -ErrorAction SilentlyContinue

        if ($command) {
            $AkeylessPath = $command.Source
        }
    }

    if (-not $AkeylessPath) {
        throw "Akeyless CLI not found. Ensure it is pre-installed in the container image."
    }

    $env:AKEYLESS_EXE_PATH = $AkeylessPath

    Write-Output "[OK] Akeyless CLI found"

    # Signing configuration is supplied by AWS Parameter Store through
    # the Buildkite pre-command hook.
    $requiredVariables = @(
        "OMNIBUS_DS_PATH",
        "OMNIBUS_AZURE_KEY_VAULT_URL",
        "OMNIBUS_AZURE_CERT_NAME"
    )

    foreach ($required in $requiredVariables) {
        $value = [Environment]::GetEnvironmentVariable($required)

        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "$required not set. Expected it from .buildkite/hooks/pre-command."
        }
    }

    # Do not print configuration values into CI logs.
    Write-Output "[OK] Akeyless signing metadata available"
}


function Sign-ChefPackage {
    [CmdletBinding()]
    param()

    Write-Output "--- Verifying Chef MSI signature"

    try {
        $msiPath = Get-ChildItem `
            -Path "C:\omnibus-ruby\chef\pkg\" `
            -Filter "*.msi" `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if (-not $msiPath) {
            throw "No MSI file found in C:\omnibus-ruby\chef\pkg\"
        }

        $msiPath = $msiPath.FullName

        Write-Output "Found MSI: $(Split-Path $msiPath -Leaf)"

        $sig = Get-AuthenticodeSignature -FilePath $msiPath

        if ($null -eq $sig.SignerCertificate) {
            throw "MSI has no signer certificate (file may be unsigned)"
        }

        Write-Output "  Status:     $($sig.Status)"
        Write-Output "  Subject:    $($sig.SignerCertificate.Subject)"
        Write-Output "  Issuer:     $($sig.SignerCertificate.Issuer)"
        Write-Output "  Thumbprint: $($sig.SignerCertificate.Thumbprint)"

        if ($sig.Status -ne "Valid") {
            throw "Signature verification failed: $($sig.Status)"
        }

        Write-Output "[OK] Signature is valid"

        # Subject is the certificate holder (Progress Software);
        # Issuer is the certificate authority.
        if ($sig.SignerCertificate.Issuer -like "*GlobalSign*" -and
            $sig.SignerCertificate.Subject -like "*PROGRESS*") {

            Write-Output "[OK] Progress EV certificate confirmed"
        }
        else {
            Write-Warning `
                "Unexpected certificate. Issuer: $($sig.SignerCertificate.Issuer) Subject: $($sig.SignerCertificate.Subject)"
        }
    }
    catch {
        Write-Error "Failed to verify MSI signature: $_"
        throw
    }
}


function Install-ChefFoundation {
    [CmdletBinding()]
    param(
        [string]$Version = $env:CHEF_FOUNDATION_VERSION,
        [string]$WindowsVersion = "2022",
        [string]$Architecture = "x64"
    )

    try {
        Write-Output "--- Installing Chef Foundation ${Version}"

        $tempDir = Join-Path $env:TEMP "chef-foundation"

        if (-not (Test-Path $tempDir)) {
            New-Item `
                -Path $tempDir `
                -ItemType Directory `
                -Force |
                Out-Null
        }

        $msiUrl = `
            "https://packages.chef.io/files/stable/chef-foundation/${Version}/windows/${WindowsVersion}/chef-foundation-${Version}-1-${Architecture}.msi"

        $msiFile = Join-Path `
            $tempDir `
            "chef-foundation-$Version.msi"

        Write-Output "Downloading Chef Foundation MSI"

        Invoke-WebRequest `
            -Uri $msiUrl `
            -OutFile $msiFile `
            -UseBasicParsing

        if (-not (Test-Path $msiFile)) {
            throw "Chef Foundation MSI was not downloaded"
        }

        if ((Get-Item $msiFile).Length -eq 0) {
            throw "Chef Foundation MSI is empty"
        }

        Write-Output "Installing Chef Foundation MSI"

        $p = Start-Process `
            -FilePath "msiexec.exe" `
            -ArgumentList "/qn /i `"$msiFile`"" `
            -Passthru `
            -Wait `
            -NoNewWindow

        if ($p.ExitCode -eq 1618) {
            Write-Warning `
                "Another MSI installation is in progress (exit code 1618), installation might be incomplete"
        }
        elseif ($p.ExitCode -ne 0) {
            throw "MSI installation failed with exit code $($p.ExitCode)"
        }

        Write-Output "Chef Foundation $Version installed successfully"

        Remove-Item `
            -Path $msiFile `
            -Force `
            -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to install Chef Foundation: $_"
        throw
    }
}


function Ensure-DotNetRuntime {
    [CmdletBinding()]
    param()

    Write-Output "--- Validating .NET runtime"

    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue

    if (-not $dotnetCmd) {
        throw ".NET runtime not found in PATH. Ensure it is pre-installed in the container."
    }

    $env:DOTNET_ROOT = Split-Path `
        -Path $dotnetCmd.Source `
        -Parent

    $version = (dotnet --version 2>&1).Trim()

    Write-Output "[OK] dotnet $version available"
}


function Install-OmnibusDependencies {
    [CmdletBinding()]
    param()

    $netrcPath = "$env:USERPROFILE\_netrc"

    try {
        Write-Output "--- Preparing Omnibus dependencies"

        # libyajl2 must be reinstalled to include libyajldll.a
        # for Windows native gem embedding.
        Write-Output "Removing libyajl2 for reinstall"

        gem uninstall -I libyajl2

        if ([string]::IsNullOrEmpty($env:GITHUB_TOKEN)) {
            throw "GITHUB_TOKEN is not set. Cannot access private GitHub dependencies."
        }

        $token = $env:GITHUB_TOKEN.Trim()

        # Write .netrc for git HTTPS authentication.
        # Do not print the file contents.
        "machine github.com login $token password x-oauth-basic" |
            Out-File `
                -FilePath $netrcPath `
                -Encoding ascii `
                -Force

        icacls `
            $netrcPath `
            /inheritance:r `
            /grant:r "$($env:USERNAME):(R)" |
            Out-Null

        # Remove token from environment as soon as .netrc is created.
        Remove-Item Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue

        Write-Output "--- Configuring Bundler"

        bundle config set --local without development

        Set-Location "$($ScriptDir)/../../omnibus"

        Write-Output "--- Running bundle install"

        bundle install

        if ($LASTEXITCODE -ne 0) {
            throw "bundle install failed with exit code $LASTEXITCODE"
        }

        Write-Output "--- Omnibus dependencies installed successfully"
    }
    catch {
        Write-Error "Failed to install Omnibus dependencies: $_"

        Write-Output "--- Debug: Current directory contents"

        Get-ChildItem -Force |
            Select-Object Name, Length

        throw
    }
    finally {
        if (Test-Path $netrcPath) {
            Remove-Item `
                $netrcPath `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}


function Build-ChefPackage {
    [CmdletBinding()]
    param()

    try {
        Write-Output "--- Building Chef"

        Set-Location "$($ScriptDir)/../../omnibus"

        $AWS_REGION = if ($env:AWS_REGION) {
            $env:AWS_REGION
        }
        else {
            "us-west-2"
        }

        # Existing S3/cache behavior intentionally preserved.
        $BUILD_OPTIONS = "-l internal --populate-s3-cache"

        $BUILD_OPTIONS += " --override"
        $BUILD_OPTIONS += " s3_region:$AWS_REGION"
        $BUILD_OPTIONS += " s3_access_key:$($env:AWS_S3_ACCESS_KEY)"
        $BUILD_OPTIONS += " s3_secret_key:$($env:AWS_S3_SECRET_KEY)"
        $BUILD_OPTIONS += " cache_suffix:$($env:PROJECT_NAME)"
        $BUILD_OPTIONS += " append_timestamp:false"
        $BUILD_OPTIONS += " use_git_caching:true"
        $BUILD_OPTIONS += " --log-level debug"

        $env:BUNDLE_GEMFILE = `
            (Get-Location).Path + "/Gemfile"

        Write-Output "Using Omnibus Gemfile"

        Write-Output "Starting omnibus build"

        $buildArgs = `
            $BUILD_OPTIONS -split ' ' |
            Where-Object { $_ -ne '' }

        # windows_base.rb performs the actual Azure Key Vault signing.
        & bundle exec omnibus build `
            $env:PROJECT_NAME `
            @buildArgs

        if ($LASTEXITCODE -ne 0) {
            throw "Omnibus build failed with exit code $LASTEXITCODE"
        }

        Write-Output "Omnibus build completed successfully"
    }
    catch {
        Write-Error "Chef build failed: $_"

        Write-Output "--- Attempting to collect detailed build logs"

        Get-ChildItem `
            "C:\omnibus-ruby\log\" `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*build*.log" } |
            ForEach-Object {
                Write-Output "=== Log file: $($_.FullName) ==="

                Get-Content `
                    $_.FullName `
                    -Tail 200
            }

        throw "Chef build failed. See logs for details."
    }
}


function Upload-BuildkiteArtifact {
    [CmdletBinding()]
    param()

    try {
        Write-Output "--- Uploading package to Buildkite"

        & C:\buildkite-agent\bin\buildkite-agent.exe `
            artifact upload `
            "C:\omnibus-ruby\chef\pkg\*.msi*"

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to upload artifact to Buildkite"
        }
    }
    catch {
        Write-Error "Failed to upload artifact: $_"
        throw
    }
}


function Publish-ToArtifactory {
    [CmdletBinding()]
    param()

    try {
        if ($env:BUILDKITE_ORGANIZATION_SLUG -ne "chef-oss") {

            Write-Output "--- Setting up Gem API Key"

            $env:GEM_HOST_API_KEY = `
                "Basic ${env:ARTIFACTORY_API_KEY}"

            Write-Output "--- Publishing package to Artifactory"

            bundle exec ruby `
                "${ScriptDir}/omnibus_chef_publish.rb"

            if ($LASTEXITCODE -ne 0) {
                throw "Chef publish failed"
            }
        }
        else {
            Write-Output `
                "--- Skipping Artifactory publish for chef-oss organization"
        }
    }
    catch {
        Write-Error "Failed to publish to Artifactory: $_"
        throw
    }
}


# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------

try {
    Initialize-Environment
    Initialize-ProgressSigning
    Ensure-DotNetRuntime

    Install-ChefFoundation
    Install-OmnibusDependencies

    Build-ChefPackage

    # MSI signing happens inside windows_base.rb during the omnibus build.
    # This function ONLY verifies the resulting signature.
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

    Write-Output "--- Cleaning up sensitive environment variables"

    # Azure credentials are normally removed by windows_base.rb immediately
    # after signing. This is defense-in-depth cleanup for the container.
    $sensitiveEnvVars = @(
        "AZURE_TENANT_ID",
        "AZURE_CLIENT_ID",
        "AZURE_CLIENT_SECRET",

        "AWS_ACCESS_KEY_ID",
        "AWS_SECRET_ACCESS_KEY",
        "AWS_SESSION_TOKEN",

        "AWS_S3_ACCESS_KEY",
        "AWS_S3_SECRET_KEY",

        "AKEYLESS_ACCESS_ID",

        "ARTIFACTORY_PASSWORD",
        "ARTIFACTORY_API_KEY",

        "GITHUB_TOKEN",
        "GEM_HOST_API_KEY",

        "OMNIBUS_SUBMODULE_CONFIG_PRIVATE"
    )

    foreach ($var in $sensitiveEnvVars) {
        if (Test-Path "env:\$var") {
            Remove-Item `
                -Path "env:\$var" `
                -ErrorAction SilentlyContinue
        }
    }

    $netrcPath = "$env:USERPROFILE\_netrc"

    if (Test-Path $netrcPath) {
        Remove-Item `
            $netrcPath `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Write-Output "Credential cleanup complete"
}