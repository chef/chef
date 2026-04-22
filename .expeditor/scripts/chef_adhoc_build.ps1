# PowerShell equivalent of chef_adhoc_build.sh

# Enable strict mode - equivalent to bash 'set -euo pipefail'
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Ensuring habitat 2.0.504 is installed
$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"

$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path += ";C:\buildkite-agent\bin"

Write-Host "Verifying we have access to buildkite-agent"
buildkite-agent --version

# Set environment variables - equivalent to bash export commands
$env:HAB_ORIGIN = 'chef'
$env:PLAN = 'chef-infra-client'
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"
$env:HAB_BLDR_CHANNEL = "base-2025"
$env:HAB_CACHE_KEY_PATH = "C:\Users\buildkite-agent\.hab\cache\keys"

Write-Host "--- :key: Downloading origin keys"
hab origin key download $env:HAB_ORIGIN
if ($LASTEXITCODE -ne 0) { throw "Unable to download public origin key" }

hab origin key download $env:HAB_ORIGIN --secret
if ($LASTEXITCODE -ne 0) { throw "Unable to download secret origin key" }

# Verify keys were downloaded and cached
$habCachePath = if ($env:HAB_CACHE_KEY_PATH) { $env:HAB_CACHE_KEY_PATH } else { "$env:SystemDrive\hab\cache\keys" }

Write-Host "Verifying origin keys in cache: $habCachePath"

# Check if cache directory exists
if (-not (Test-Path $habCachePath)) {
    throw "Habitat cache directory not found: $habCachePath. Key download may have failed."
}

# Verify secret key exists
$secretKey = Get-ChildItem "$habCachePath\$env:HAB_ORIGIN-*.sig.key" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $secretKey) {
    throw "No secret key found for origin $env:HAB_ORIGIN in $habCachePath"
}

# Verify public key exists
$publicKey = Get-ChildItem "$habCachePath\$env:HAB_ORIGIN-*.pub" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $publicKey) {
    throw "No public key found for origin $env:HAB_ORIGIN in $habCachePath"
}

Write-Host "Found secret key: $($secretKey.Name)"
Write-Host "Found public key: $($publicKey.Name)"
Write-Host "Origin keys downloaded and cached successfully"

Write-Host "--- Building Chef Infra Client package"
$env:HAB_REFRESH_CHANNEL = "base-2025"

# Ensure Habitat cache directories exist before building.
# hab-studio on Windows creates junction links to these paths and fails if they are missing.
$habCacheDirs = @(
    "$env:SystemDrive\hab\cache\artifacts"
    # "$env:SystemDrive\hab\cache\keys"
)
foreach ($dir in $habCacheDirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating missing Habitat cache directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

hab pkg build .
if ($LASTEXITCODE -ne 0) { throw "Unable to build package" }

# Source the build environment - equivalent to sourcing last_build.env (Windows generates last_build.ps1)
$project_root = git rev-parse --show-toplevel
$results_dir = Join-Path $project_root "results"
$build_script_path = Join-Path $results_dir "last_build.ps1"

if (-not (Test-Path $build_script_path)) {
    throw "Build script not found: $build_script_path"
}

. $build_script_path

Set-Location $results_dir
buildkite-agent artifact upload $pkg_artifact
if ($LASTEXITCODE -ne 0) { throw "Unable to upload package" }

Write-Host "--- Setting INFRA_HAB_ARTIFACT_WINDOWS metadata for buildkite agent"
Write-Host "setting INFRA_HAB_ARTIFACT_WINDOWS to $pkg_artifact"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT_WINDOWS" $pkg_artifact
if ($LASTEXITCODE -ne 0) { throw "Unable to set buildkite metadata" }
