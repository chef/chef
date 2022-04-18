$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

Set-Item -Path Env:Path -Value ("C:\Program Files\Git\mingw64\bin;C:\Program Files\Git\usr\bin;" + $Env:Path)

winrm quickconfig -q

Write-Output "+++ bundle exec rake spec:integration"
bundle exec rake spec:integration --trace
if (-not $?) { throw "Chef integration specs failing." }
