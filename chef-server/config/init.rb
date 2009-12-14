# Go to http://wiki.merbivore.com/pages/init-rb

require 'config/dependencies.rb'
unless defined?(Chef)
  gem "chef", "=" + CHEF_SERVER_VERSION if CHEF_SERVER_VERSION
  require 'chef'  
end

File.umask Chef::Config[:umask]

use_test :rspec
use_template_engine :haml

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:fork_for_class_load] = false
  c[:log_level] = Chef::Config[:log_level]
  if Chef::Config[:log_location].kind_of?(String)
    c[:log_file] = Chef::Config[:log_location]
  end
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.  OpenID::Util.logger = Merb.logger
end

