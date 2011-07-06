require File.dirname(__FILE__) + '/lib/chef-server-api/version'

Gem::Specification.new do |s|
  s.name = "chef-server-api"
  s.version = ChefServerApi::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "config.ru", "development.ru" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.author = "Opscode"
  s.email = "chef@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "merb-core", "~> 1.1.0"
  s.add_dependency "merb-assets", "~> 1.1.0"
  s.add_dependency "merb-helpers", "~> 1.1.0"
  s.add_dependency "merb-param-protection", "~> 1.1.0"

  s.add_dependency "mixlib-authentication", '>= 1.1.3'

  s.add_dependency "dep_selector", ">= 0.0.3"

  s.add_dependency "json", ">= 1.4.4", "<= 1.4.6"

  s.add_dependency "uuidtools", "~> 2.1.1"

  s.add_dependency "thin"

  s.bindir       = "bin"
  s.executables  = %w( chef-server )

  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile) + Dir.glob("{config,lib,spec,app,public,stubs}/**/*")
end
