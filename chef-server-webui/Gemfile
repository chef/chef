$:.push File.expand_path("../lib", __FILE__)
require "chef-server-webui/version"

source :rubygems

gemspec

gem "chef", ChefServerWebui::VERSION, :require => false # load individual parts as needed
gem "chef-solr", ChefServerWebui::VERSION, :require => false

group(:dev) do
  gem 'thin'
end

group(:prod) do
  gem "unicorn", "~> 2.0.0"
end
