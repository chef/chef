habitat_sup "default" do
  license "accept"
  gateway_auth_token "secret"
end

ruby_block "wait-for-svc-default-startup" do
  block do
    # Check if the Windows service is actually running instead of checking loaded services
    cmd = Mixlib::ShellOut.new("powershell -Command \"(Get-Service habitat).Status -eq 'Running'\"")
    cmd.run_command

    if cmd.stdout.strip == "True"
      puts "Habitat service is running"
    else
      raise "Habitat service is not running yet"
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
