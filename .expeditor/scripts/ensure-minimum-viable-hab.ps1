$required_hab_version = [Version]"1.6.125"
$hab_install_script_url = 'https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1'
$hab_install_script_path = Join-Path $env:TEMP 'hab-install.ps1'

function Install-RequiredHabitat {
    $web_client = New-Object System.Net.WebClient
    $web_client.DownloadFile($hab_install_script_url, $hab_install_script_path)
    & $hab_install_script_path -Version $required_hab_version
}

try {
    [Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
    if ($hab_version -ne $required_hab_version) {
        Write-Host "--- :habicat: Installing Habitat $required_hab_version"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Install-RequiredHabitat
        if (-not $?) { throw "Hab version is $hab_version and could not be updated to $required_hab_version." }
    } else {
        Write-Host "--- :habicat: :thumbsup: Required Habitat version $required_hab_version already installed"
    }
}
catch {
    # This install fails if Hab isn't on the path when we check for the version. This ensures the required version is installed.
    Write-Host "--- :habicat: Installing Habitat $required_hab_version"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Install-RequiredHabitat
}