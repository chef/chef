require File.dirname(__FILE__) + '/lib/chef-server/version'

Gem::Specification.new do |s|
  s.name = "chef-server"
  s.version = ChefServer::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.summary = "A meta-gem to install all server components of the Chef configuration management system"
  s.description = s.summary
  s.author = "Opscode"
  s.email = "chef@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "chef-server-api",   "= #{ChefServer::VERSION}"
  s.add_dependency "chef-server-webui", "= #{ChefServer::VERSION}"
  s.add_dependency "chef-expander",     "= #{ChefServer::VERSION}"
  s.add_dependency "chef-solr",         "= #{ChefServer::VERSION}"

  s.files = %w(LICENSE README.rdoc Rakefile lib/chef-server.rb lib/chef-server/version.rb)
  s
end

