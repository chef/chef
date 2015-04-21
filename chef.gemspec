$:.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/version'

Gem::Specification.new do |s|
  s.name = 'chef'
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.md", "CONTRIBUTING.md", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io"
  s.homepage = "http://www.chef.io"

  s.required_ruby_version = ">= 2.0.0"

  s.add_dependency "mixlib-config", "~> 2.0"
  s.add_dependency "mixlib-cli", "~> 1.4"
  s.add_dependency "mixlib-log", "~> 1.3"
  s.add_dependency "mixlib-authentication", "~> 1.3"
  s.add_dependency "mixlib-shellout", ">= 2.0.0.rc.0", "< 3.0"
  s.add_dependency "ohai", "~> 8.0"

  s.add_dependency "ffi-yajl", ">= 1.2", "< 3.0"
  s.add_dependency "net-ssh", "~> 2.6"
  s.add_dependency "net-ssh-multi", "~> 1.1"
  # CHEF-3027: The knife-cloud plugins require newer features from highline, core chef should not.
  s.add_dependency "highline", "~> 1.6", ">= 1.6.9"
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "diff-lcs", "~> 1.2", ">= 1.2.4"

  s.add_dependency "chef-zero", "~> 4.1"
  s.add_dependency "pry", "~> 0.9"

  s.add_dependency 'plist', '~> 3.1.0'

  # Audit mode requires these, so they are non-developmental dependencies now
  %w(rspec-core rspec-expectations rspec-mocks).each { |gem| s.add_dependency gem, "~> 3.2" }
  s.add_dependency "rspec_junit_formatter", "~> 0.2.0"
  s.add_dependency "serverspec", "~> 2.7"
  s.add_dependency "specinfra", "~> 2.10"

  s.add_development_dependency "rack"

  # Rake 10.2 drops Ruby 1.8 support
  s.add_development_dependency "rake", "~> 10.1.0"

  s.bindir       = "bin"
  s.executables  = %w( chef-client chef-solo knife chef-shell chef-apply )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md CONTRIBUTING.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
