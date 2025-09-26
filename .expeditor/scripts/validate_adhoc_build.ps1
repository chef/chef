$ErrorActionPreference = 'Stop'

# Ensure git safe directory
git config --global --add safe.directory /workdir

# Ensure Habitat is installed (helper script)
$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path += ";C:\buildkite-agent\bin"

# Accept licenses
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"

Write-Host "Verifying buildkite-agent access"
buildkite-agent --version

# Download package artifact using metadata
Write-Host "--- Downloading package artifact"
$env:PKG_ARTIFACT = buildkite-agent meta-data get "INFRA_HAB_ARTIFACT_WINDOWS"
buildkite-agent artifact download "$env:PKG_ARTIFACT" .

# Download and import public origin key with fixed name
Write-Host "--- Downloading and importing public origin key"
$origin_key = "ci-windows-key.pub"
buildkite-agent artifact download $origin_key "./$origin_key"
if (-not (Test-Path $origin_key)) { throw "Origin key artifact not found after download" }

Get-Content $origin_key | hab origin key import
if (-not $?) { throw "Unable to import origin public key" }

# Install the package
Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT --auth $env:HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

# Resolve package identifier
$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

Write-Host "--- Resolved package identifier: $pkgIdent, running tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "Failed to verify adhoc build" }

Write-Host "--- Validation script completed successfully"
