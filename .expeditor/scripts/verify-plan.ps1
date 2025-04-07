#!/usr/bin/env powershell

#Requires -Version 5

param(
    # The name of the plan that is to be built.
    [string]$Plan
)

$env:HAB_ORIGIN = 'ci'
$Plan = 'chef-infra-client'

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
$env:DO_CHECK=$true; hab pkg build .
if (-not $?) { throw "unable to build"}

. results/last_build.ps1
if (-not $?) { throw "unable to determine details about this build"}

Write-Host "--- :hammer_and_wrench: Installing $pkg_ident"
hab pkg install results/$pkg_artifact
if (-not $?) { throw "unable to install this build"}

Write-Host "--- :gem: Verifying REXML gem version"
$rexml_output = & hab pkg exec $pkg_ident gem list rexml
if ($rexml_output -match "rexml \(([\d., ]+)\)") {
    $versions = $matches[1].Split(",").Trim()
    $min_version = [System.Version]"3.3.6"
    $old_versions = $versions | Where-Object {
        $v = [System.Version]($_ -replace '^(\d+\.\d+\.\d+).*$', '$1')
        $v -lt $min_version
    }

    if ($old_versions) {
        Write-Host "--- :warning: Found old REXML versions: $($old_versions -join ', '). Uninstalling..."
        foreach ($version in $old_versions) {
            & hab pkg exec $pkg_ident gem uninstall rexml -v $version --force
            if (-not $?) { throw "Failed to uninstall REXML version $version" }
        }
        Write-Host "--- :white_check_mark: Old REXML versions uninstalled"
    } else {
        Write-Host "REXML version check passed"
    }
} else {
    throw "Unable to determine REXML gem versions"
}

Write-Host "--- :mag_right: Testing $Plan"
powershell -File "./habitat/tests/test.ps1" -PackageIdentifier $pkg_ident
if (-not $?) { throw "package didn't pass the test suite" }

Write-Host "--- :gem: Verifying REXML gem version"
$rexml_output = & hab pkg exec $pkg_ident gem list rexml
if ($rexml_output -match "rexml \(([\d., ]+)\)") {
    $versions = $matches[1].Split(",").Trim()
    $min_version = [System.Version]"3.3.6"
    $old_versions = $versions | Where-Object {
        $v = [System.Version]($_ -replace '^(\d+\.\d+\.\d+).*$', '$1')
        $v -lt $min_version
    }

    if ($old_versions) {
        throw "Found old REXML versions: $($old_versions -join ', '). Minimum required version is 3.3.6"
    }
    Write-Host "REXML version check passed"
} else {
    throw "Could not determine REXML gem version"
}