$ErrorActionPreference = 'Stop'

$EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS=$args[0]

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
# . ./scripts/ensure-minimum-viable-hab.ps1
Write-Host "--- Installing $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
hab pkg install $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
. ./habitat/tests/test.ps1 -PackageIdentifier $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
