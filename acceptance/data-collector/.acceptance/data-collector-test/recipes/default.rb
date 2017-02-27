api_root_dir = "/var/opt/data_collector_api"

directory api_root_dir do
  recursive true
end

cookbook_file ::File.join(api_root_dir, "Gemfile") do
  source "apigemfile"
end

cookbook_file ::File.join(api_root_dir, "config.ru")

cookbook_file ::File.join(api_root_dir, "api.rb")

execute "bundle install --binstubs" do
  cwd api_root_dir
end

pid_file    = "/var/run/api.pid"
running_pid = ::File.exist?(pid_file) ? ::File.read(pid_file).strip : nil

execute "kill existing API process" do
  command "kill #{running_pid}"
  not_if { running_pid.nil? }
end

execute "start API" do
  command "bin/rackup -D -P #{pid_file}"
  cwd api_root_dir
end

directory "/etc/chef"

["both-mode", "client-mode", "no-endpoint", "solo-mode"].each do |config_file|
  cookbook_file "/etc/chef/#{config_file}.rb" do
    source "client-rb-#{config_file}.rb"
  end
end
