$:.push File.expand_path("../lib", __FILE__)
require "chef-server-webui/version"

source :rubygems

gemspec

gem "chef", ChefServerWebui::VERSION, :git => "git://github.com/opscode/chef.git", :require => false # load individual parts as needed
gem "chef-solr", ChefServerWebui::VERSION, :git => "git://github.com/opscode/chef.git", :require => false

group(:dev) do
  gem 'thin'
end

group(:prod) do
  gem "unicorn", "~> 2.0.0"
end
