#
# ==== Standalone Chefserver configuration
# 
# This configuration/environment file is only loaded by bin/slice, which can be 
# used during development of the slice. It has no effect on this slice being
# loaded in a host application. To run your slice in standalone mode, just
# run 'slice' from its directory. The 'slice' command is very similar to
# the 'merb' command, and takes all the same options, including -i to drop 
# into an irb session for example.
#
# The usual Merb configuration directives and init.rb setup methods apply,
# including use_orm and before_app_loads/after_app_loads.
#
# If you need need different configurations for different environments you can 
# even create the specific environment file in config/environments/ just like
# in a regular Merb application. 
#
# In fact, a slice is no different from a normal # Merb application - it only
# differs by the fact that seamlessly integrates into a so called 'host'
# application, which in turn can override or finetune the slice implementation
# code and views.
#


require "merb-core" 
require "merb-haml"
require "merb-assets"
require "merb-helpers"

require 'coderay'

require 'chef'
require 'chef/solr'

require 'chef/role'
require 'chef/webui_user'


use_template_engine :haml

Merb::Config.use do |c|
  # BUGBUG [cb] For some reason, this next line
  # causes a merb slice to vomit around openid
  #c[:fork_for_class_load] = false
  c[:session_id_key]     = '_chef_server_session_id'
  c[:session_secret_key] = Chef::Config.manage_secret_key
  c[:session_store]      = 'cookie'
  c[:exception_details]  = true
  c[:reload_classes]     = true
  c[:reload_templates]   = true
  
  c[:log_level] = Chef::Config[:log_level]
  if Chef::Config[:log_location].kind_of?(String)
    c[:log_file] = Chef::Config[:log_location]
  end
end

Chef::Config[:node_name] = Chef::Config[:web_ui_client_name]
Chef::Config[:client_key] = Chef::Config[:web_ui_key]

# Create the default admin user "admin" if no admin user exists  
unless Chef::WebUIUser.admin_exist
  user = Chef::WebUIUser.new
  user.name = Chef::Config[:web_ui_admin_user_name]
  user.set_password(Chef::Config[:web_ui_admin_default_password])
  user.admin = true
  user.save
end
