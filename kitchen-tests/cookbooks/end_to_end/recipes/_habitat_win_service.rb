habitat_sup "default" do
  license "accept"
  gateway_auth_token "secret"
end

ruby_block "wait-for-svc-default-startup" do
  block do
    # Check if the habitat service is running, regardless of whether services are loaded
    cmd = Mixlib::ShellOut.new("hab sup status", returns: [0, 1])
    cmd.run_command
    
    # Consider a success if either:
    # 1. The command succeeds (return code 0), meaning hab supervisor is running and has services
    # 2. The output contains "No services loaded" which means hab supervisor is running but no services are loaded yet
    unless cmd.exitstatus == 0 || cmd.stdout =~ /No services loaded/
      raise "Habitat supervisor is not running properly. Output: #{cmd.stdout}, Error: #{cmd.stderr}"
    end
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
