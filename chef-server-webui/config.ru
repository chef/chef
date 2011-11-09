require 'rubygems'
require 'merb-core'
require 'chef'

#Chef::Config.from_file(File.join("/etc", "chef", "server.rb"))
Chef::Config.from_file(File.expand_path(File.dirname(__FILE__) + '/../features/data/config/server.rb'))

Merb::Config.setup(:merb_root   => File.expand_path(File.dirname(__FILE__)),
                   :environment => 'production',
                   :fork_for_class_load => false)

Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

use Merb::Rack::Static, Merb.dir_for(:public)

run Merb::Rack::Application.new


