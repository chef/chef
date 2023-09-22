chef_gem 'chef-reporting' do
  action :install
end

chef_client_config "Create chef-client's client.rb" do
  require 'chef_reporting'

  chef_server_url "https://localhost"
  log_location windows? ? "C:\\chef\\log_test\\client.log" : "/var/log/chef/log_test/client.log"
  chef_license "accept"

  report_handlers  << Chef::Handler::JsonFile.new(:path => '/tmp/chef_report_handler.json')
  exception_handlers << Chef::Handler::JsonFile.new(:path => '/tmp/chef_exception_handler.json')
  start_handlers     << Chef::Reporting::StartHandler.new

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
