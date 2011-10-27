require 'rubygems'
require 'merb-core'
require 'chef'

Chef::Config.from_file(File.join("/etc", "chef", "server.rb"))

Merb::Config.setup(:merb_root   => File.expand_path(File.dirname(__FILE__)),
                   :environment => 'production',
                   :fork_for_class_load => false,
                   :init_file => File.dirname(__FILE__) / "config/init.rb")
Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

# Uncomment if your app is mounted at a suburi
#if prefix = ::Merb::Config[:path_prefix]
#  use Merb::Rack::PathPrefix, prefix
#end

run Merb::Rack::Application.new

