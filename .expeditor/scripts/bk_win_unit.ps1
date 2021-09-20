$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

$env:RUBY_DLL_PATH = "${CurrentDirectory}\..\..\vendor\bundle\ruby\3.0.0\gems\mixlib-archive-1.1.7-universal-mingw32\distro\ruby_bin_folder"

echo "+++ bundle exec rake"
bundle exec rake spec:unit
if (-not $?) { throw "Chef unit tests failing." }
bundle exec rake component_specs
if (-not $?) { throw "Chef component specs failing." }
