
$ErrorActionPreference = "Stop"

function test-script {

    $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS = 'chef/chef-infra-client/18.0.179/20221109104144'
    Write-Output "################ Testing EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS ##############"
    . ./.expeditor/scripts/ensure-minimum-viable-hab.ps1
    Write-Host "--- Installing $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS"
    env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    hab pkg install $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
    . ./habitat/tests/test.ps1 -PackageIdentifier $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
}

test-script