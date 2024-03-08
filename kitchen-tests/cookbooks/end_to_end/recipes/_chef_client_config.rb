chef_client_config "default" do
  chef_license "accept"
  chef_server_url "https://localhost/organizations/test"
  file_backup_path windows? ? "C:/chef/backup" : "/var/lib/chef"
  log_location value_for_platform_family(
                 windows: "C:/chef/log/client.log",
                 mac_os_x: "/Library/Logs/Chef/client.log",
                 default: "/var/log/chef/client.log"
               )
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
