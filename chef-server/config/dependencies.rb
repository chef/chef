# dependencies are generated using a strict version, don't forget to edit the dependency versions when upgrading.
merb_gems_version = "> 1.0"

%w{chef chef-server-api chef-solr}.each do |dep|
  $:.unshift(File.join(File.dirname(__FILE__), "..", "..", dep, "lib"))
end

begin
  require 'chef'
  require 'chef-server-api'
rescue
end
  
# For more information about each component, please read http://wiki.merbivore.com/faqs/merb_components
dependency "merb-core", merb_gems_version 
dependency "merb-assets", merb_gems_version  
dependency "merb-helpers", merb_gems_version 
dependency "merb-slices", merb_gems_version  
if defined?(CHEF_SERVER_VERSION)
  dependency "chef-server-api", CHEF_SERVER_VERSION unless defined?(ChefServerApi)
else
  dependency "chef-server-api" unless defined?(ChefServerApi)
end

