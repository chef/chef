require 'rubygems'
require 'merb-core'
require 'chef'

Chef::Config.from_file(File.join("/etc", "chef", "server.rb"))

Merb::Config.setup(:merb_root   => File.expand_path(File.dirname(__FILE__)), 
                   :environment => 'production',
                   :fork_for_class_load => false,
                   :init_file => File.dirname(__FILE__) / "config/init-webui.rb")
Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

Merb::Slices.config.each do |slice_module, config|
  slice_module = Object.full_const_get(slice_module.to_s.camel_case) if slice_module.class.in?(String, Symbol)
  slice_module.send("public_components").each do |component|
    slice_static_dir = slice_module.send("dir_for", :public)
    use Merb::Rack::Static, slice_static_dir
  end
end

run Merb::Rack::Application.new


