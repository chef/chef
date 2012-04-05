require 'chef'

#Chef::Config.from_file(File.join("/etc", "chef", "server.rb"))
Chef::Config.from_file(File.expand_path(File.dirname(__FILE__) + '/../features/data/config/server.rb'))

require ::File.expand_path('../config/environment',  __FILE__)
run ChefServerWebui::Application
