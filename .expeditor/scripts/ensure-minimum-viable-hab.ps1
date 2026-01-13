try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]"0.85.0" ) {
        Write-Host "--- :habicat: Installing the version of Habitat required"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
        if (-not $?) { throw "Hab version is older than 0.85 and could not update it." }
    } else {
        Write-Host "--- :habicat: :thumbsup: Minimum required version of Habitat already installed"
    }
}
catch {
    # This install fails if Hab isn't on the path when we check for the version. This ensures it is installed
    Write-Host "--- :habicat: Installing the version of Habitat required"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
}