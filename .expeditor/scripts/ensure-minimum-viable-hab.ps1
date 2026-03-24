$HabitatVersion = if ($env:HAB_VERSION) { $env:HAB_VERSION } else { '2.0.450' }

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

try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Installing Habitat $HabitatVersion"
        Install-HabitatVersion
    } elseif ($hab_version -gt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Habitat $hab_version detected (greater than required $HabitatVersion). Removing with prejudice..."
        $habPath = (Get-Command hab -ErrorAction SilentlyContinue).Source | Split-Path -Parent
        if ($habPath) {
            Remove-Item -Path $habPath -Recurse -Force -ErrorAction Continue
            Write-Host "--- :habicat: Deleted Habitat from $habPath"
        }
        Install-HabitatVersion
    } else {
        Write-Host "--- :habicat: :thumbsup: Habitat $HabitatVersion is already installed"
    }
}
catch {
    Write-Host "--- :habicat: Installing Habitat $HabitatVersion..."
    Install-HabitatVersion
}
