$ErrorActionPreference = "Stop"

# Validate required environment variable exists
if (-not $env:ARTIFACTORY_LITA_PASSWORD) {
    Write-Host "CRITICAL: ARTIFACTORY_LITA_PASSWORD environment variable not found" -ForegroundColor Red
    Write-Host "This variable should be set by the pre-command hook for pipeline: chef-chef-main-gem-validate-release" -ForegroundColor Red
    exit 1
}

Write-Host "Using Artifactory credentials from environment (injected by pre-command hook)"

# Set environment variables
$env:HAB_ORIGIN = "chef"
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"
$env:HAB_BLDR_CHANNEL = "base-2025"
$env:PROJECT_NAME = "chef"
$env:ARTIFACTORY_ENDPOINT = "https://artifactory-internal.ps.chef.co/artifactory"
$env:ARTIFACTORY_USERNAME = "buildkite"

powershell -File "./.expeditor/scripts/ensure-minimum-viable-hab.ps1"
if (-not $?) { throw "Could not ensure the minimum hab version required is installed." }
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = "C:\hab\bin;" + $env:Path # add hab bin path for binlinking so 'gem' command is found.

Write-Output "--- Installing core/ruby3_4-plus-devkit via Habitat"
hab pkg install core/ruby3_4-plus-devkit --channel base-2025 --binlink --force
if (-not $?) { throw "Could not install ruby with devkit via Habitat." }

Write-Output "--- Building and pushing gems to Artifactory"
try {
    # Use password from environment (no AWS call needed)
    $lita_password = $env:ARTIFACTORY_LITA_PASSWORD

    # Create base64 encoded API key
    $credentials = "lita:$lita_password"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($credentials)
    $artifactory_api_key = [System.Convert]::ToBase64String($bytes)
    $env:GEM_HOST_API_KEY = "Basic $artifactory_api_key"

    # Clear sensitive variables from memory
    $lita_password = $null
    $credentials = $null

    # Generate origin key
    Write-Host "Generating origin key"
    hab origin key generate $env:HAB_ORIGIN

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to generate origin key"
    }

    # Build gems via habitat
    Write-Host "Building gems via habitat"
    hab pkg build . --refresh-channel base-2025

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to build package" -ForegroundColor Yellow
        throw "Failed to build habitat package"
    }

    # Push gems to artifactory
    Write-Host "Push gems to artifactory"
    gem install artifactory -v 3.0.17 --no-document

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install artifactory gem"
    }

    ruby .expeditor/scripts/gem_push_artifactory.rb

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push gems to artifactory"
    }

    Write-Host "Gem push to artifactory completed successfully" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
