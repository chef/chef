#!/usr/bin/env powershell

#Requires -Version 5

param(
  [Parameter(Mandatory = $true)]
  [string]$ChefRepoRoot
)

$ErrorActionPreference = "Stop"

$lockfile = Join-Path $ChefRepoRoot "Gemfile.lock"
$lockfile_contents = Get-Content $lockfile -Raw
$source_pattern = '(?ms)^GIT\r?\n  remote: https://github\.com/chef/chef-powershell-shim\r?\n  revision: ([0-9a-f]+)'
$source_match = [regex]::Match($lockfile_contents, $source_pattern)
if (-not $source_match.Success) {
  throw "Could not find the chef-powershell-shim revision in $lockfile"
}

$revision = $source_match.Groups[1].Value
$source_dir = "C:\chef-ps-ci"
if (-not (Test-Path $source_dir)) {
  git clone --no-checkout https://github.com/chef/chef-powershell-shim $source_dir
  if ($LASTEXITCODE -ne 0) { throw "Failed to clone chef-powershell-shim" }
}

Push-Location $source_dir
try {
  git fetch origin $revision
  if ($LASTEXITCODE -ne 0) { throw "Failed to fetch chef-powershell-shim revision $revision" }

  git checkout --force $revision
  if ($LASTEXITCODE -ne 0) { throw "Failed to check out chef-powershell-shim revision $revision" }

  if (-not (Get-Command hab -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.ps1"))
  }

  $env:MSBuildEnableWorkloadResolver = "false"
  $env:HAB_ORIGIN = "chef"
  $env:HAB_LICENSE = "accept-no-persist"
  $env:HAB_BLDR_CHANNEL = "base-2025"
  $env:HAB_REFRESH_CHANNEL = "base-2025"
  $env:FORCE_FFI_YAJL = "ext"

  $origin_key = Get-ChildItem C:\hab\cache\keys -Filter "$env:HAB_ORIGIN-*.sig.key" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $origin_key) {
    hab origin key generate $env:HAB_ORIGIN
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate the Habitat origin key" }
  }

  hab pkg build habitat --refresh-channel base-2025
  if ($LASTEXITCODE -ne 0) { throw "Failed to build chef-powershell-shim" }

  . .\results\last_build.ps1
  hab pkg install "results\$pkg_artifact"
  if ($LASTEXITCODE -ne 0) { throw "Failed to install $pkg_artifact" }

  $package_path = (& hab pkg path $pkg_ident).Trim()
  if ($LASTEXITCODE -ne 0 -or -not $package_path) { throw "Failed to locate $pkg_ident" }

  $env:CHEF_POWERSHELL_BIN = Join-Path $package_path "bin"
  if (-not (Test-Path $env:CHEF_POWERSHELL_BIN)) {
    throw "Chef PowerShell DLL directory does not exist: $env:CHEF_POWERSHELL_BIN"
  }

  if ($env:GITHUB_ENV) {
    "CHEF_POWERSHELL_BIN=$env:CHEF_POWERSHELL_BIN" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
  }

  Write-Host "Using chef-powershell DLLs from $env:CHEF_POWERSHELL_BIN"

  # spec/support/ruby_installer.rb locates Chef.PowerShell.dll by globbing
  # Gem.dir (and C:/hab) for bin/ruby_bin_folder/<arch>/Chef.PowerShell.dll -
  # it has no knowledge of CHEF_POWERSHELL_BIN. When chef-powershell is
  # sourced from git (see Gemfile), the checked-out gem has no prebuilt DLLs,
  # so drop the ones we just built into the installed git gem's directory
  # too. This only applies when chef-powershell has already been bundle
  # installed from a Gemfile.lock on this host (e.g. the unit/func spec
  # workflows); the Habitat plan build packages its own copy independently
  # (see habitat/x86_64-windows/plan.ps1), so skip this quietly otherwise.
  Push-Location $ChefRepoRoot
  try {
    $gem_path = (bundle info chef-powershell --path 2>$null | Select-Object -Last 1)
    if ($LASTEXITCODE -eq 0 -and $gem_path -and (Test-Path $gem_path)) {
      $architecture = if ($env:PROCESSOR_ARCHITECTURE) { $env:PROCESSOR_ARCHITECTURE } else { "AMD64" }
      $dll_destination = Join-Path $gem_path "bin\ruby_bin_folder\$architecture"
      New-Item -Path $dll_destination -ItemType Directory -Force | Out-Null
      Copy-Item "$env:CHEF_POWERSHELL_BIN\*" -Destination $dll_destination -Recurse -Force
      Write-Host "Copied chef-powershell DLLs into $dll_destination"
    }
    else {
      Write-Host "chef-powershell gem not found via 'bundle info' - skipping DLL copy into the installed gem"
    }
  }
  finally {
    Pop-Location
  }
}
finally {
  Pop-Location
}
