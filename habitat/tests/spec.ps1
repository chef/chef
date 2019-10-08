param (
    [Parameter()]
    [string]$PackageIdentifier = $(throw "Usage: test.ps1 [test_pkg_ident] e.g. test.ps1 ci/user-windows/1.0.0/20190812103929")
)

# some of the functional tests require that winrm be configured
winrm quickconfig -quiet

$chef_gem_root = (hab pkg exec $PackageIdentifier gem.cmd which chef | Split-Path | Split-Path)
try {
    Push-Location $chef_gem_root
    hab pkg binlink --force $PackageIdentifier
    /hab/bin/rspec --format progress --tag ~executables --tag ~choco_installed spec/functional
    if (-not $?) { throw "functional testing failed"}
} finally {
    Pop-Location
}