habitat_sup "default" do
  license "accept"
  gateway_auth_token "secret"
end

powershell_script 'habitat-diagnostics' do
  code <<-PS1
    Write-Host "Checking Habitat service status..."
    Get-Service -Name Habitat -ErrorAction SilentlyContinue | Format-List Status,Name,DisplayName,StartType

    Write-Host "Checking Habitat Supervisor processes..."
    Get-Process -Name hab-sup -ErrorAction SilentlyContinue | Format-List

    Write-Host "Checking network connectivity..."
    Test-NetConnection -ComputerName localhost -Port 9631 | Format-List

    Write-Host "Checking Windows firewall status..."
    Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Habitat*" -or $_.DisplayName -like "*9631*"} | Format-List
  PS1
  action :run
end

# ruby_block 'delay_before_habitat_connection' do
#   block do
#     Chef::Log.info('Waiting for Habitat supervisor to be fully initialized...')
#     sleep 15  # Adjust this value as needed (seconds)
#     Chef::Log.info('Delay completed, proceeding with habitat connection')
#   end
#   action :run
# end

ruby_block "wait-for-svc-default-startup" do
  block do
    raise unless system("hab svc status")
  end
  retries 30
  retry_delay 1
end

habitat_service "chef/splunkforwarder" do
  gateway_auth_token "secret"
end

# we need this sleep to let splunkforwarder start and for the hab supervisor to
# recognize this and write the state file out otherwise our functional
# tests fail.
ruby_block "wait-for-splunkforwarder-start" do
  block do
    sleep 3
  end
  action :nothing
  subscribes :run, "habitat_service[chef/splunkforwarder]", :immediately
end

habitat_service "chef/splunkforwarder unload" do
  service_name "chef/splunkforwarder"
  gateway_auth_token "secret"
  action :unload
end

habitat_service "chef/sensu-agent-win" do
  strategy "rolling"
  update_condition "latest"
  channel :stable
  gateway_auth_token "secret"
  action :load
end

# we need this sleep to let sensu-agent-win start and for the hab supervisor to
# recognize this and write the state file out otherwise our functional
# tests fail.
ruby_block "wait-for-sensu-agent-win-start" do
  block do
    sleep 5
  end
  action :nothing
  subscribes :run, "habitat_service[chef/sensu-agent-win]", :immediately
end

habitat_service "chef/sensu-agent-win stop" do
  service_name "chef/sensu-agent-win"
  gateway_auth_token "secret"
  action :stop
end
