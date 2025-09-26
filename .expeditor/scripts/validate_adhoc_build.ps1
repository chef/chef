$ErrorActionPreference = 'Stop'

git config --global --add safe.directory /workdir

# Ensure Habitat is installed (helper script)
$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
$env:Path += ";C:\buildkite-agent\bin"

# Ensure Chef and Habitat licenses are accepted
$env:CHEF_LICENSE = "accept-no-persist"
$env:HAB_LICENSE = "accept-no-persist"
$env:HAB_NONINTERACTIVE = "true"

Write-Host "Verifying we have access to buildkite-agent"
buildkite-agent --version

Write-Host "--- Downloading package artifact"
$env:PKG_ARTIFACT = $(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT_WINDOWS")
buildkite-agent artifact download "$env:PKG_ARTIFACT" .

Write-Host "--- Downloading and importing public origin key"
$origin_key = "ci-windows-key.pub"
buildkite-agent artifact download $origin_key .
Get-Content $origin_key | hab origin key import
if (-not $?) { throw "Unable to import origin public key" }

Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT --auth $env:HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

# Resolve package identifier
$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

Write-Host "--- Resolved package identifier: $pkgIdent, running tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
