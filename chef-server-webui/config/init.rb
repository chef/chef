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

$: << File.join(File.dirname(__FILE__), "..", "..", "chef", "lib")
require 'chef'

merb_gems_version = " > 1.0"
dependency "merb-haml", merb_gems_version
dependency "merb-assets", merb_gems_version
dependency "merb-helpers", merb_gems_version
dependency "chef", :immediate=>true unless defined?(Chef)

use_template_engine :haml

Merb::Config.use do |c|
  # BUGBUG [cb] For some reason, this next line
  # causes a merb slice to vomit around openid
  #c[:fork_for_class_load] = false
  c[:session_id_key] = '_chef_server_session_id'
  c[:session_secret_key]  = Chef::Config.manage_secret_key
  c[:session_store] = 'cookie'
  c[:exception_details] = true
  c[:reload_classes] = true 
  c[:log_level] = Chef::Config[:log_level]
  if Chef::Config[:log_location].kind_of?(String)
    c[:log_file] = Chef::Config[:log_location]
  end
end

