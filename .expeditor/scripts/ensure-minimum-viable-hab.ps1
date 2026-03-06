$HabitatVersion = if ($env:HAB_VERSION) { $env:HAB_VERSION } else { '1.6.1245' }
try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]$HabitatVersion ) {
        Write-Host "--- :habicat: Installing Habitat $HabitatVersion"
        Set-ExecutionPolicy Bypass -Scope Process -Force

        $installScriptUrl = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
        $installScriptPath = Join-Path $env:TEMP "hab-install-$HabitatVersion.ps1"

        Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath
        & $installScriptPath -Version $HabitatVersion
        if (-not $?) { throw "Failed to install Habitat $HabitatVersion" }
    } elseif ($hab_version -gt [Version]$HabitatVersion) {
        Write-Host "--- :habicat: Habitat $hab_version detected (greater than required $HabitatVersion). Removing with prejudice..."
        Set-ExecutionPolicy Bypass -Scope Process -Force

        # Remove Habitat installation
        $habPath = (Get-Command hab -ErrorAction SilentlyContinue).Source | Split-Path -Parent
        if ($habPath) {
            Remove-Item -Path $habPath -Recurse -Force -ErrorAction Continue
            Write-Host "--- :habicat: Deleted Habitat from $habPath"
        }

        # Reinstall correct version
        $installScriptUrl = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
        $installScriptPath = Join-Path $env:TEMP "hab-install-$HabitatVersion.ps1"

        Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath
        & $installScriptPath -Version $HabitatVersion
        if (-not $?) { throw "Failed to install Habitat $HabitatVersion" }
    } else {
        Write-Host "--- :habicat: :thumbsup: Habitat $HabitatVersion is already installed"
    }
}
catch {
  Write-Host "--- :habicat: Installing Habitat $HabitatVersion..."
  $installScriptUrl = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
  $installScriptPath = Join-Path $env:TEMP "hab-install-$HabitatVersion.ps1"

  Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath
  try {
    & $installScriptPath -Version $HabitatVersion
  }
  finally {
    Remove-Item $installScriptPath -Force -ErrorAction SilentlyContinue
  }
}
