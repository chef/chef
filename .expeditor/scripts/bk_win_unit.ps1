$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

$gemdir = (bundle exec gem environment gemdir)
$libarchive_dir = (Get-ChildItem -Recurse -Path $gemdir -Filter libarchive.dll)[0].Directory.FullName
Write-Output "libarchive_dir: ${libarchive_dir}"
$env:RUBY_DLL_PATH = $libarchive_dir

echo "+++ bundle exec rake"
bundle exec rake spec:unit
if (-not $?) { throw "Chef unit tests failing." }
bundle exec rake component_specs
if (-not $?) { throw "Chef component specs failing." }
