file "/tmp/foo" do
  owner  "adam"
  mode   0644
  action :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end

link "/tmp/foo" do
  link_type :symbolic
  target_file "/tmp/xmen"
end
