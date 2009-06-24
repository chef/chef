# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'
unless defined?(Chef)
  gem "chef", "=" + CHEF_SERVER_VERSION if CHEF_SERVER_VERSION
  require 'chef'  
end

use_test :rspec
use_template_engine :haml

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_id_key] = '_chef_server_session_id'
  c[:session_secret_key]  = Chef::Config.manage_secret_key
  c[:session_store] = 'cookie'
  c[:exception_details] = true
  c[:reload_classes] = false
  c[:log_level] = Chef::Config[:log_level]
  c[:log_stream] = Chef::Config[:log_location]
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  OpenID::Util.logger = Merb.logger
end
