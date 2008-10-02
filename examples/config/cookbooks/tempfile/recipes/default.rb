file "/tmp/glen" do
  owner  "adam"
  mode   0755
  action "create"
end

file "/tmp/metallica" do
  action [ :create, :touch, :delete ]
end

directory "/tmp/marginal" do
  owner "adam"
  mode 0755
  action :create
end

remote_directory "/tmp/rubygems" do
  owner "adam"
  mode 0755
  source "packages"
  files_owner "adam"
  files_group "adam"
  files_mode 0755
end
