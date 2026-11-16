$HabitatVersion = if ($env:HAB_VERSION) { $env:HAB_VERSION } else { '2.1.23' }

Set-ExecutionPolicy Bypass -Scope Process -Force

$installScriptUrl = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
$installScriptPath = Join-Path $env:TEMP "hab-install-$HabitatVersion.ps1"

function Install-HabitatVersion {
    Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath
    try {
        & $installScriptPath -Version $HabitatVersion
        if (-not $?) { throw "Failed to install Habitat $HabitatVersion" }
    }
    finally {
        Remove-Item $installScriptPath -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "--- :habicat: Ensuring minimum viable habitat installation.."

try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Habitat $hab_version detected (below minimum $HabitatVersion). Installing..."
        Install-HabitatVersion
    } else {
        Write-Host "--- :habicat: :thumbsup: Habitat $hab_version is installed (>= $HabitatVersion)"
    }
}
catch {
    Write-Host "hab not found or version check failed: $_"
    Write-Host "--- :habicat: Installing Habitat $HabitatVersion..."
    Install-HabitatVersion
}
