require File.dirname(__FILE__) + '/lib/chef/version'

Gem::Specification.new do |s|
  s.name = 'chef'
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.author = "Adam Jacob"
  s.email = "adam@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "mixlib-config", ">= 1.1.2"
  s.add_dependency "mixlib-cli", ">= 1.1.0"
  s.add_dependency "mixlib-log", ">= 1.2.0"
  s.add_dependency "mixlib-authentication", ">= 1.1.0"
  s.add_dependency "ohai", ">= 0.5.7"

  s.add_dependency "rest-client", ">= 1.0.4", "< 1.7.0"
  s.add_dependency "bunny", ">= 0.6.0"
  s.add_dependency "json", ">= 1.4.4", "<= 1.4.6"
  %w{erubis extlib moneta highline uuidtools}.each { |gem| s.add_dependency gem }

  s.bindir       = "bin"
  s.executables  = %w( chef-client chef-solo knife shef )
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc) + Dir.glob("{distro,lib}/**/*")
end
