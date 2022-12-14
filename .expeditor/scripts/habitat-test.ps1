
$ErrorActionPreference = "Stop"


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


function test-script {

    $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS = 'chef/chef-infra-client/18.0.179/20221109104144'
    Write-Output "################ Testing EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS ##############"
    Write-Host "--- Installing $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    hab pkg install $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
    . ./habitat/tests/test.ps1 -PackageIdentifier $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
}

test-script