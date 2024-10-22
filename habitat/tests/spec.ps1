param (
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows/1.0.0/20190812103929")
)

# some of the functional tests require that winrm be configured
winrm quickconfig -quiet

$chef_gem_root = (hab pkg exec $PackageIdentifier gem.cmd which chef | Split-Path | Split-Path)
try {
    Push-Location $chef_gem_root
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

    hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/unit
    if (-not $?) { throw "Unit tests failed"}

    hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/functional
    if (-not $?) { throw "Functional tests failed"}

    hab pkg exec $PackageIdentifier rspec -f progress --profile -- ./spec/integration
    if (-not $?) { throw "Integration tests failed"}
} finally {
    Pop-Location
}
