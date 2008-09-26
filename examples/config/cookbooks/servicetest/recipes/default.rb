service "puppet-client" do
  service_name "puppet"
  action :disable
end

service "mysql" do
  
  action [ :enable, :running ]
end