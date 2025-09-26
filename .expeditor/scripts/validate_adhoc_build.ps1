$ErrorActionPreference = 'Stop'

git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
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

Write-Host "Downloading and importing origin key"
buildkite-agent artifact download "ci-windows-key.pub" .
Get-Content "ci-windows-key.pub" | hab origin key import
if (-not $?) { throw "Unable to import origin key" }

Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT --auth $HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

Write-Host "--- Resolved package identifier: \"$pkgIdent\", attempting to run tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
