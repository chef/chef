$:.push File.expand_path("../lib", __FILE__)
require "chef-server-webui/version"

source :rubygems

gem "haml"
gem "ruby-openid"
gem "coderay"

merb_gems_version = "1.1.3"
gem "merb-core", merb_gems_version
gem "merb-assets", merb_gems_version
gem "merb-haml", merb_gems_version
gem "merb-helpers", merb_gems_version
gem "merb-param-protection", merb_gems_version

gem "chef", ChefServerWebui::VERSION, :require => false # load individual parts as needed
gem "chef-solr", ChefServerWebui::VERSION, :require => false

group(:dev) do
  gem "thin"
  gem "pry"
end

group(:prod) do
  gem "unicorn", "~> 2.0.0"
end
