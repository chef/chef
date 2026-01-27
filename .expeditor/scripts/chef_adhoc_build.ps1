# PowerShell equivalent of chef_adhoc_build.sh

# Enable strict mode - equivalent to bash 'set -euo pipefail'
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Install Habitat for Windows - equivalent to install-hab.sh x86_64-linux
Write-Host "--- :habicat: Installing Habitat for Windows"
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
} catch {
    Write-Host "$($_ | Format-List * -Force | Out-String)"
    throw "Unable to install Habitat"
}
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

Write-Host "--- :key: Downloading origin key"
hab origin key download $env:HAB_ORIGIN
hab origin key download $env:HAB_ORIGIN --secret
if (-not $?) { throw "Unable to download origin key" }

Write-Host "--- :key: Importing origin keys into studio"
# Import the downloaded keys to make them available in the local studio
# On Windows, hab stores keys in $env:HAB_CACHE_KEY_PATH or default location
$habCachePath = if ($env:HAB_CACHE_KEY_PATH) { $env:HAB_CACHE_KEY_PATH } else { "$env:SystemDrive\hab\cache\keys" }

Write-Host "Looking for keys in: $habCachePath"

# Find the most recent secret and public keys for the origin
$secretKey = Get-ChildItem "$habCachePath\$env:HAB_ORIGIN-*.sig.key" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

$publicKey = Get-ChildItem "$habCachePath\$env:HAB_ORIGIN-*.pub" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($secretKey) {
    Write-Host "Importing secret key: $($secretKey.Name)"
    $keyContent = Get-Content $secretKey.FullName -Raw
    $keyContent | hab origin key import
    if (-not $?) { throw "Unable to import secret origin key" }
} else {
    Write-Host "Warning: No secret key found for origin $env:HAB_ORIGIN"
}

if ($publicKey) {
    Write-Host "Importing public key: $($publicKey.Name)"
    $keyContent = Get-Content $publicKey.FullName -Raw
    $keyContent | hab origin key import
    if (-not $?) { throw "Unable to import public origin key" }
} else {
    throw "No public key found for origin $env:HAB_ORIGIN"
}

Write-Host "--- Building Chef Infra Client package"
hab pkg build . --refresh-channel base-2025
if (-not $?) { throw "Unable to build package" }

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
if (-not $?) { throw "Unable to upload package" }

Write-Host "--- Setting INFRA_HAB_ARTIFACT_WINDOWS metadata for buildkite agent"
Write-Host "setting INFRA_HAB_ARTIFACT_WINDOWS to $pkg_artifact"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT_WINDOWS" $pkg_artifact
if (-not $?) { throw "Unable to set buildkite metadata" }
