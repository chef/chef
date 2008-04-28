file "/tmp/foo" do
  owner  "adam"
  mode   0644
  action :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end
