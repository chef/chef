require File.dirname(__FILE__) + '/lib/chef-server-webui/version'

Gem::Specification.new do |s|
  s.name = "chef-server-webui"
  s.version = ChefServerWebui::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE", "config.ru" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.author = "Opscode"
  s.email = "chef@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "chef"
  s.add_dependency "thin"
  s.add_dependency "rails", "3.2.2"
  s.add_dependency "jquery-rails"
  s.add_dependency "haml-rails"
  s.add_dependency "ruby-openid"
  s.add_dependency "coderay"

  s.add_development_dependency "rspec-rails"

  s.bindir       = "bin"
  s.executables  = %w( chef-server-webui )

  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile config.ru) + Dir.glob("{bin,config,lib,spec,app,public,stubs}/**/*")
end
