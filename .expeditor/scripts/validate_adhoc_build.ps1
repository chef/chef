$ErrorActionPreference = 'Stop'

git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "--- Downloading package artifact"
$env:PKG_ARTIFACT = $(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT")
buildkite-agent artifact download "$env:PKG_ARTIFACT" .

Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

echo "--- Resolved package identifier: \"$pkgIdent\", attempting to run tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
