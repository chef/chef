$ErrorActionPreference = 'Stop'


git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path += ";C:\buildkite-agent\bin"

# Ensure Chef and Habitat licenses are accepted
$env:HAB_ORIGIN = 'chef'
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"
$env:HAB_BLDR_CHANNEL = "base-2025"

Write-Host "Verifying we have access to buildkite-agent"
buildkite-agent --version

Write-Host "--- Downloading package artifact"
$env:PKG_ARTIFACT = $(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT_WINDOWS")
buildkite-agent artifact download "$env:PKG_ARTIFACT" .

Write-Host ":key: Downloading origin key"
hab origin key download $env:HAB_ORIGIN
if (-not $?) { throw "Unable to download origin key" }

Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT --auth $HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

$pkgIdent = hab pkg list chef/chef-infra-client

echo "--- Resolved package identifier: \"$pkgIdent\", attempting to run tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
