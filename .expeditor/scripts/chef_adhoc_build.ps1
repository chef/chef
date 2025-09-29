# PowerShell: Build/Export Phase (run on builder agent)

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
$env:Path += ";C:\buildkite-agent\bin"

Write-Host "Verifying we have access to buildkite-agent"
buildkite-agent --version

# Set environment variables
$env:HAB_ORIGIN = 'ci'
$env:PLAN = 'chef-infra-client'
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"
$env:HAB_BLDR_CHANNEL = "base-2025"

if (-not $env:HAB_ORIGIN) {
    throw "HAB_ORIGIN environment variable must be set!"
}

Write-Host "--- :key: Generating fake origin key"
hab origin key generate $env:HAB_ORIGIN
if (-not $?) { throw "Unable to generate origin key" }

Write-Host "--- Building Chef Infra Client package"
hab pkg build . --refresh-channel base-2025
if (-not $?) { throw "Unable to build package" }

$project_root = git rev-parse --show-toplevel
$results_dir = Join-Path $project_root "results"
$build_script_path = Join-Path $results_dir "last_build.ps1"
. $build_script_path

Set-Location $results_dir
buildkite-agent artifact upload $pkg_artifact
if (-not $?) { throw "Unable to upload package" }

Write-Host "--- Setting INFRA_HAB_ARTIFACT_WINDOWS metadata for buildkite agent"
Write-Host "setting INFRA_HAB_ARTIFACT_WINDOWS to $pkg_artifact"
buildkite-agent meta-data set "INFRA_HAB_ARTIFACT_WINDOWS" $pkg_artifact
if (-not $?) { throw "Unable to set buildkite metadata" }

# --- FIXED KEY EXPORT SECTION ---
$key_file = "$($env:HAB_ORIGIN)-windows-key.pub"
hab origin key export --type=public $env:HAB_ORIGIN | Out-String | % { $_ -replace "(`r`n|`n|`r)", "" } | Set-Content -NoNewline -Encoding ascii $key_file
if (-not $?) { throw "Unable to export origin key" }

# Verification
Write-Host "--- Verifying exported key file content"
Get-Content $key_file

Write-Host "--- Verifying exported key file hex dump"
Format-Hex $key_file

buildkite-agent artifact upload "$key_file"
if (-not $?) { throw "Unable to upload origin key" }
