file "/tmp/foo" do
  owner    "adam"
  mode     0644
  action   :create
  notifies :delete, resources(:file => "/tmp/glen"), :delayed
end

link "/tmp/foo" do
  link_type   :symbolic
  target_file "/tmp/xmen"
end

0.upto(1000) do |n|
  file "/tmp/somefile#{n}" do
    owner  "adam"
    mode   0644
    action :create
  end
end