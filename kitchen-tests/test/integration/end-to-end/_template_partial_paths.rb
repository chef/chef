describe file("/tmp/chef-template-partial-paths") do
  it { should exist }
  its("content") { should include("before /etc/chef/client.rb,/etc/chef/client.pem after") }
end
