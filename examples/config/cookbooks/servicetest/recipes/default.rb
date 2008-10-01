service "puppet-client" do
  service_name "puppet"
  pattern "puppetd"
  action :start
end

file "/tmp/foo" do
  owner    "aj"
  mode     0644
  action   :create
  notifies :start, resources(:service => "puppet-client"), :immediate
end
