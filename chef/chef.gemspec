$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/version'

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
  s.add_dependency "mixlib-log", ">= 1.3.0"
  s.add_dependency "mixlib-authentication", ">= 1.1.0"
  s.add_dependency "mixlib-shellout", "~> 1.0.0.rc"
  s.add_dependency "ohai", ">= 0.6.0"

  s.add_dependency "rest-client", ">= 1.0.4", "< 1.7.0"
  s.add_dependency "bunny", ">= 0.6.0"
  s.add_dependency "json", ">= 1.4.4", "<= 1.6.1"
  s.add_dependency "treetop", "~> 1.4.9"
  s.add_dependency "net-ssh", "~> 2.2.2"
  s.add_dependency "net-ssh-multi", "~> 1.1.0"
  %w{erubis moneta highline uuidtools}.each { |gem| s.add_dependency gem }

  %w(rdoc sdoc ronn rake rspec_junit_formatter).each { |gem| s.add_development_dependency gem }

  %w(rspec-core rspec-expectations rspec-mocks).each { |gem| s.add_development_dependency gem, "< 2.9.0" }

  s.bindir       = "bin"
  s.executables  = %w( chef-client chef-solo knife shef )
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc) + Dir.glob("{distro,lib}/**/*")
end
