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

$requiredHabVersionString = "1.6.1245"
$requiredHabVersion = [Version]$requiredHabVersionString
$currentHabVersion = $null

try {
	$habVersionOutput = hab --version
	if ($habVersionOutput) {
		$currentHabVersion = [Version]($habVersionOutput.Split(" ")[1].Split("/")[0])
	}
} catch {
	Write-Host "--- :habicat: Unable to determine Habitat version, forcing install of $requiredHabVersionString"
}

if ($currentHabVersion -ne $requiredHabVersion) {
	Write-Host "--- :habicat: Habitat version '$currentHabVersion' detected, forcing install of $requiredHabVersionString"
	Set-ExecutionPolicy Bypass -Scope Process -Force

	$habCommand = Get-Command hab -ErrorAction SilentlyContinue
	if ($habCommand) {
		$habPath = $habCommand.Source | Split-Path -Parent
		if ($habPath) {
			Remove-Item -Path $habPath -Recurse -Force -ErrorAction Continue
			Write-Host "--- :habicat: Deleted Habitat from $habPath"
		}
	}

	$installScriptUrl = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
	$installScriptPath = Join-Path $env:TEMP "hab-install-$requiredHabVersionString.ps1"

	Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath
	try {
		& $installScriptPath -Version $requiredHabVersionString
		if (-not $?) { throw "Failed to install Habitat $requiredHabVersionString" }
	}
	finally {
		Remove-Item $installScriptPath -Force -ErrorAction SilentlyContinue
	}

	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
	$env:Path += ";C:\buildkite-agent\bin"
}

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
