$HabitatVersion = if ($env:HAB_VERSION) { $env:HAB_VERSION } else { '2.0.504' }

Set-ExecutionPolicy Bypass -Scope Process -Force

function Stop-HabitatProcesses {
    # Stop any running hab-related processes to release file locks (e.g. concrt140.dll)
    # that would prevent the installer from overwriting existing files.
    $habProcesses = Get-Process -Name hab*, hab-launch*, hab-sup* -ErrorAction SilentlyContinue
    if ($habProcesses) {
        Write-Host "Stopping running Habitat processes to release file locks..."
        $habProcesses | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

function Install-HabitatVersion {
    Stop-HabitatProcesses
    iex "& { $(irm https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1) } -Version $HabitatVersion"
    if (-not $?) { throw "Failed to install Habitat $HabitatVersion" }
}

try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Installing Habitat $HabitatVersion"
        Install-HabitatVersion
    } elseif ($hab_version -gt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Installing Habitat $HabitatVersion (replacing $hab_version)"
        Install-HabitatVersion
    } else {
        Write-Host "--- :habicat: :thumbsup: Habitat $HabitatVersion is already installed"
    }
}
catch {
    Write-Host "--- :habicat: Installing Habitat $HabitatVersion..."
    Install-HabitatVersion
}
