require File.dirname(__FILE__) + '/lib/chef/solr/version'

Gem::Specification.new do |gem|
  gem.name = "chef-solr"
  gem.version = Chef::Solr::VERSION
  gem.summary = %Q{Search indexing for Chef}
  gem.email = "adam@opscode.com"
  gem.homepage = "http://wiki.opscode.com/display/chef"
  gem.authors = ["Adam Jacob"]
  gem.add_dependency "chef", Chef::Solr::VERSION
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  gem.executables = [ 'chef-solr', 'chef-solr-installer' ]
  gem.files = [
    "README.rdoc",
    "Rakefile"
  ]
  gem.files = %w{ README.rdoc Rakefile LICENSE} + Dir.glob("{bin,lib,solr,spec}/**/*")
end
