template "/etc/chef-server/chef-pedant-config.rb" do
  owner "root"
  group "root"
  mode  "0755"
  variables :api_url  => node['chef_server']['nginx']['url'],
            :solr_url => node['chef_server']['chef-solr']['url']
end
