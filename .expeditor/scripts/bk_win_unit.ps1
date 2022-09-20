$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

#echo "+++ bundle exec rake spec:unit"
#bundle exec rake spec:unit
#if (-not $?) { throw "Chef unit tests failing." }
echo "+++ bundle exec rake component_specs"
bundle exec rake component_specs
if (-not $?) { throw "Chef component specs failing." }
