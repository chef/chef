# Enable strict mode - equivalent to bash 'set -euo pipefail'
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Install Habitat for Windows
Write-Host "--- :habicat: Installing Habitat for Windows"
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
} catch {
    throw "Unable to install Habitat"
}

# Refresh PATH to include Buildkite agent binaries
$env:Path += ";C:\buildkite-agent\bin"

Write-Host "Verifying we have access to buildkite-agent"
buildkite-agent --version

# Set environment variables
$env:HAB_ORIGIN          = 'ci'
$env:PLAN                = 'chef-infra-client'
$env:CHEF_LICENSE        = "accept-no-persist"
$env:HAB_LICENSE         = "accept-no-persist"
$env:HAB_NONINTERACTIVE  = "true"
$env:HAB_BLDR_CHANNEL    = "base-2025"

Write-Host "--- :key: Generating origin key (if not already exists)"
hab origin key generate $env:HAB_ORIGIN
if (-not $?) { throw "Unable to generate origin key" }

Write-Host "--- Building Chef Infra Client package"
hab pkg build . --refresh-channel $env:HAB_BLDR_CHANNEL
if (-not $?) { throw "Unable to build package" }

# Source the build environment (Windows = last_build.ps1)
$project_root      = git rev-parse --show-toplevel
$results_dir       = Join-Path $project_root "results"
$build_script_path = Join-Path $results_dir "last_build.ps1"
. $build_script_path

# Upload package artifact
Set-Location $results_dir
Write-Host "--- Uploading package artifact: $pkg_artifact"
buildkite-agent artifact upload $pkg_artifact
if (-not $?) { throw "Unable to upload package artifact" }

Write-Host "--- Setting INFRA_HAB_ARTIFACT_WINDOWS metadata for Buildkite agent"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT_WINDOWS" $pkg_artifact
if (-not $?) { throw "Unable to set Buildkite metadata" }

# Export PUBLIC origin key only (safe to share)
$key_file = Join-Path $results_dir "ci-windows-key.pub"
Write-Host "--- Exporting public origin key to $key_file"
hab origin key export --type=public $env:HAB_ORIGIN | Out-File -Encoding ascii -NoNewline -FilePath $key_file
if (-not $?) { throw "Unable to export origin public key" }

Write-Host "--- Uploading public origin key artifact"
buildkite-agent artifact upload $key_file
if (-not $?) { throw "Unable to upload origin public key" }

Write-Host "--- Build and upload process completed successfully"
