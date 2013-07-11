$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/version'

Gem::Specification.new do |s|
  s.name = 'chef'
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.md", "CONTRIBUTING.md", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.author = "Adam Jacob"
  s.email = "adam@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "mixlib-config", ">= 1.1.2"
  s.add_dependency "mixlib-cli", "~> 1.3.0"
  s.add_dependency "mixlib-log", ">= 1.3.0"
  s.add_dependency "mixlib-authentication", ">= 1.3.0"
  s.add_dependency "mixlib-shellout"
  s.add_dependency "ohai", ">= 0.6.0"

  s.add_dependency "rest-client", ">= 1.0.4", "< 1.7.0"

  # The JSON gem reliably releases breaking changes as a patch release
  s.add_dependency "json", ">= 1.4.4", "<=  1.7.7"
  s.add_dependency "yajl-ruby", "~> 1.1"
  s.add_dependency "net-ssh", "~> 2.6"
  s.add_dependency "net-ssh-multi", "~> 1.1.0"
  # CHEF-3027: The knife-cloud plugins require newer features from highline, core chef should not.
  s.add_dependency "highline", ">= 1.6.9"
  s.add_dependency "erubis"

  %w(rdoc sdoc rake rack rspec_junit_formatter).each { |gem| s.add_development_dependency gem }
  %w(rspec-core rspec-expectations rspec-mocks).each { |gem| s.add_development_dependency gem, "~> 2.13.0" }
  s.add_development_dependency "chef-zero", "~> 1.4"
  s.add_development_dependency "puma", "~> 1.6"

  s.bindir       = "bin"
  # chef-service-manager is a windows only executable.
  # However gemspec doesn't give us a way to have this executable only
  # on windows. So we're including this in all platforms.
  s.executables  = %w( chef-client chef-solo knife chef-shell shef chef-apply chef-service-manager )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md CONTRIBUTING.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
