param ($WindowsArtifact = $(throw "WindowsArtifact parameter is required."))
$ErrorActionPreference = 'Stop'

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
# . ./scripts/ensure-minimum-viable-hab.ps1
Write-Host "--- Installing $WindowsArtifact"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

hab pkg install $WindowsArtifact
if (-not $?) { throw "Unable to install $WindowsArtifact" }

. ./habitat/tests/test.ps1 -PackageIdentifier $WindowsArtifact
if (-not $?) { throw "Habitat tests failed" }
