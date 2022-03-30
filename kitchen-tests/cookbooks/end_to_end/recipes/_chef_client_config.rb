chef_client_config "Create chef-client's client.rb" do
  chef_server_url "https://localhost"
  log_location windows? ? "C:\\chef\\log_test\\client.log" : "/var/log/chef/log_test/client.log"
  chef_license "accept"
  ohai_optional_plugins %i{Passwd Lspci Sysctl}
  ohai_disabled_plugins %i{Sessions Interrupts}
  rubygems_url "https://rubygems.org/"
  additional_config <<~CONFIG
    begin
      require 'aws-sdk'
    rescue LoadError
      Chef::Log.warn "Failed to load aws-sdk."
    end
  CONFIG
end
