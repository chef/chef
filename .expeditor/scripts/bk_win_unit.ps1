$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

Write-Output "--- Verifying the Windows version we're running on"
Write-Output (Get-WMIObject win32_operatingsystem).name

echo "+++ bundle exec rake"
bundle exec rake spec:unit
if (-not $?) { throw "Chef unit tests failing." }
bundle exec rake component_specs
if (-not $?) { throw "Chef component specs failing." }
