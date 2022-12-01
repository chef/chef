require 'chef-powershell'


include ChefPowerShell::ChefPowerShellModule::PowerShellExec

case ARGV[0]
when /pwsh/
  puts powershell_exec!('gci', :pwsh).result
when /default/
  puts powershell_exec!('gci').result
when /object/
  cmd = ChefPowerShell::PowerShell.new('gci')
  puts cmd.result
end
