$ErrorActionPreference = 'Stop'

# Add buildkite-agent's bin directory to PATH so the agent can be found directly
$env:PATH = "C:\buildkite-agent\bin;" + $env:PATH

# Optionally, ensure a 'buildkite-agent.exe' exists for compatibility
$bkStable = "C:\buildkite-agent\bin\buildkite-agent-stable.exe"
$bkExe = "C:\buildkite-agent\bin\buildkite-agent.exe"
if (!(Test-Path $bkExe) -and (Test-Path $bkStable)) {
    Copy-Item $bkStable $bkExe
}

# Debug output
Write-Host "PATH is: $env:PATH"
Write-Host "Contents of C:\buildkite-agent\bin:"
Get-ChildItem C:\buildkite-agent\bin
Write-Host "Trying to get buildkite-agent version:"
buildkite-agent --version

git config --global --add safe.directory /workdir

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"

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
