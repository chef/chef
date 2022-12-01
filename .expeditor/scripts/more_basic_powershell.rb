require 'chef-powershell'


include ChefPowerShell::ChefPowerShellModule::PowerShellExec
puts powershell_exec!('gci', :pwsh).result
puts 'pwsh exec'
puts powershell_exec!('gci').result
puts 'vanilla exec'
cmd = ChefPowerShell::PowerShell.new('gci')
puts cmd.result
puts 'all exec'
