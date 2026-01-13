param ($WindowsArtifact = $(throw "WindowsArtifact parameter is required."))
$ErrorActionPreference = 'Stop'

# Read the CHEF_LICENSE_SERVER value from chef_license_server_url.txt
# Ideally, this value would have been read from a centralized environment such as a GitHub environment,
# Buildkite environment, or a vault, allowing for seamless updates without requiring a pull request for changes.
try {
  $licenseFile = Join-Path -Path $PSScriptRoot -ChildPath 'chef_license_server_url.txt'
  $licenseServerUrl = Get-Content -Path $licenseFile -ErrorAction Stop | Select-Object -First 1
  $env:CHEF_LICENSE_SERVER = $licenseServerUrl.Trim()
}
catch {
	Write-Host "Failed to read chef_license_server_url.txt: $($_.Exception.Message)"
}

$ScriptRoute = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, "ensure-minimum-viable-hab.ps1"))
& "$ScriptRoute"
# . ./scripts/ensure-minimum-viable-hab.ps1
Write-Host "--- Installing $WindowsArtifact"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

hab pkg install $WindowsArtifact --auth $env:HAB_AUTH_TOKEN
if (-not $?) { throw "Unable to install $WindowsArtifact" }

. ./habitat/tests/test.ps1 -PackageIdentifier $WindowsArtifact
if (-not $?) { throw "Habitat tests failed" }
