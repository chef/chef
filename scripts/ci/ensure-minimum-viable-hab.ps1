[Version]$hab_version = (hab --version).split(" ")[1].split("/")[0]
if ($hab_version -lt [Version]"0.85.0" ) {
    Write-Host "--- :habicat: Installing the version of Habitat required"
    install-habitat --version 0.85.0.20190916
    if (-not $?) { throw "Hab version is older than 0.85 and could not update it." }
} else {
    Write-Host "--- :habicat: :thumbsup: Minimum required version of Habitat already installed"
}
