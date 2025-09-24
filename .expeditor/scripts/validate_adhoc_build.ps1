$ErrorActionPreference = 'Stop'

# Add buildkite-agent directory to PATH so buildkite-agent.exe can be found
$env:PATH = "C:\buildkite-agent;" + $env:PATH

# debug output
Write-Host "PATH is: $env:PATH"
Write-Host "Contents of C:\buildkite-agent:"
Get-ChildItem C:\buildkite-agent
Write-Host "Trying to get buildkite-agent version:"
C:\buildkite-agent\buildkite-agent.exe --version

git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "--- Downloading package artifact"
$env:PKG_ARTIFACT = $(buildkite-agent meta-data get "INFRA_HAB_ARTIFACT")
buildkite-agent artifact download "$env:PKG_ARTIFACT" .

Write-Host "--- Installing $env:PKG_ARTIFACT"
hab pkg install $env:PKG_ARTIFACT --auth $HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $env:PKG_ARTIFACT" }

$pkgPath = hab pkg path chef/chef-infra-client
$pkgIdent = $pkgPath -match 'chef/chef-infra-client/\d+\.\d+\.\d+/\d+' | Out-Null; $Matches[0]

echo "--- Resolved package identifier: \"$pkgIdent\", attempting to run tests"
. ./habitat/tests/test.ps1 -PackageIdentifier $pkgIdent
if (-not $?) { throw "failed to verify adhoc build" }
