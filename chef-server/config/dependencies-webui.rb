# dependencies are generated using a strict version, don't forget to edit the dependency versions when upgrading.
merb_gems_version = "> 1.0"

%w{chef chef-server-webui}.each do |dep|
  $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", dep, "lib")))
end

dependency "chef", :immediate=>true unless defined?(Chef)

begin
  require 'chef'
  require 'chef-server-webui'
rescue
end
  
# For more information about each component, please read http://wiki.merbivore.com/faqs/merb_components
dependency "merb-core", merb_gems_version 
dependency "merb-slices", merb_gems_version  
dependency "merb-haml", merb_gems_version
dependency "merb-assets", merb_gems_version
dependency "merb-helpers", merb_gems_version
if defined?(CHEF_SERVER_VERSION)
  dependency "chef-server-webui", CHEF_SERVER_VERSION unless defined?(ChefServerWebui)
else
  dependency "chef-server-webui" unless defined?(ChefServerWebui)
end

