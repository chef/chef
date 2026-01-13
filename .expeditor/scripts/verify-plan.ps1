#!/usr/bin/env powershell

#Requires -Version 5

param(
    # The name of the plan that is to be built.
    [string]$Plan
)

$env:HAB_ORIGIN = 'chef'
$env:HAB_BLDR_CHANNEL = "base-2025"
$Plan = 'chef-infra-client'
$env:HAB_LICENSE='accept-no-persist'
$env:CHEF_LICENSE='accept-no-persist'

Write-Host "--- :8ball: :windows: Verifying $Plan"

powershell -File "./.expeditor/scripts/ensure-minimum-viable-hab.ps1"
if (-not $?) { throw "Could not ensure the minimum hab version required is installed." }
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "--- :construction: Verifying Git is Installed"
$source = Get-Command -Name Git -Verbose
Write-Host "Which version of Git is installed? - " $source.version
if (-not ($source.name -match "git.exe")) {
    choco install git -y
    # gotta refresh the path so you can actually use Git now
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

Write-Host "--- :key: Generating fake origin key"
hab origin key generate $env:HAB_ORIGIN

$project_root = "$(git rev-parse --show-toplevel)"
Set-Location $project_root

Write-Host "--- :construction: Building $Plan"
$env:DO_CHECK=$true; $env:HAB_REFRESH_CHANNEL="base-2025"; hab pkg build .
if (-not $?) { throw "unable to build"}

. results/last_build.ps1
if (-not $?) { throw "unable to determine details about this build"}

Write-Host "--- :hammer_and_wrench: Installing $pkg_ident"
hab pkg install results/$pkg_artifact
if (-not $?) { throw "unable to install this build"}

Write-Host "--- :mag_right: Testing $Plan"
powershell -File "./habitat/tests/test.ps1" -PackageIdentifier $pkg_ident
if (-not $?) { throw "package didn't pass the test suite" }
