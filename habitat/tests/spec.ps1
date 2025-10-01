param (
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows/1.0.0/20190812103929")
)

# some of the functional tests require that winrm be configured
winrm quickconfig -quiet

$env:PATH = "C:\hab\bin;$env:PATH"

# Put chef's GEM_PATH in the machine environment so that the windows service
# tests will be able to consume the win32-service gem
$pkgEnv = hab pkg env $PackageIdentifier
$gemPath = $pkgEnv | Where-Object { $_.StartsWith("`$env:GEM_PATH=") }
SETX GEM_PATH $($gemPath.Split("=")[1]) /m

hab pkg binlink --force $PackageIdentifier

# [System.Environment]::SetEnvironmentVariable("HAB_TEST", "true", "Machine")
# [System.Environment]::SetEnvironmentVariable("HAB_TEST", "true", "User")
$env:HAB_TEST="true"

# TODO need to merge this branch before these will pass, so don't throw errors just yet.
hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/unit
if (-not $?) { throw "--- :fire: Unit tests failed" }
hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/functional
if (-not $?) { throw "--- :fire: Functional tests failed" }
hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/integration
if (-not $?) { throw "--- :fire: Integration tests failed" }
