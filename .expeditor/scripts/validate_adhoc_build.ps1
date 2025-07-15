$ErrorActionPreference = 'Stop'

git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"

$env:PKG_IDENT = $(buildkite-agent meta-data get "INFRA_HAB_PKG_IDENT")

Write-Host "--- Installing latest version of $env:PKG_IDENT from unstable channel"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
hab pkg install $env:PKG_IDENT --channel unstable --auth $HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install latest package of $env:PKG_IDENT from unstable channel" }

$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

echo "--- Resolved package identifier: \"$pkgIdent\", attempting to run tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
