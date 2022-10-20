try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -lt [Version]"0.85.0" ) {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (-not $?) { throw "Hab version is older than 0.85 and could not update it." }
    } else {
        Write-Host "--- :habicat: :thumbsup: Minimum required version of Habitat already installed"
    }
}
catch {
    Write-Host "--- :habicat: Forcing an install of habitat"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    choco feature enable -n=allowGlobalConfirmation
    choco install habitat
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\ProgramData\Habitat\"
}
