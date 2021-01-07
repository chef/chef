param (
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows/1.0.0/20190812103929")
)

# ensure Pester is available for test use
if (-Not (Get-Module -ListAvailable -Name Pester)){
    hab pkg install core/pester
    Import-Module "$(hab pkg path core/pester)\module\pester.psd1"
}

Write-Host "--- :fire: Smokish Pestering"
# Pester the Package
$__dir=(Get-Item $PSScriptRoot)
$test_result = Invoke-Pester -Strict -PassThru -Script @{
    Path = "$__dir/test.pester.ps1";
    Parameters = @{PackageIdentifier=$PackageIdentifier}
}
if ($test_result.FailedCount -ne 0) { Exit $test_result.FailedCount }

Write-Host "--- :alembic: Functional Tests"
powershell -File "./habitat/tests/spec.ps1" -PackageIdentifier $PackageIdentifier
if (-not $?) { throw "functional spec suite failed" }
