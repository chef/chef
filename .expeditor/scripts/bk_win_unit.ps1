$CurrentDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$PrepScript = Join-Path $CurrentDirectory "bk_win_prep.ps1"
Invoke-Expression $PrepScript

echo "+++ Ensuring Chef-PowerShell is installed"
$is_chef_powershell_installed = gem list chef-powershell
if (-not($is_chef_powershell_installed.Contains("18"))){
    gem install chef-powershell:18.1.0
}

echo "+++ bundle exec rake"
bundle exec rake spec:unit
if (-not $?) { throw "Chef unit tests failing." }
bundle exec rake component_specs
if (-not $?) { throw "Chef component specs failing." }
