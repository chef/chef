$:.unshift(File.dirname(__FILE__) + "/lib")
require "chef/version"

Gem::Specification.new do |s|
  s.name = "chef"
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.md", "CONTRIBUTING.md", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io"
  s.homepage = "https://www.chef.io"

  s.required_ruby_version = ">= 2.3.0"

  s.add_dependency "chef-config", "= #{Chef::VERSION}"

  s.add_dependency "mixlib-cli", "~> 1.7"
  s.add_dependency "mixlib-log", "~> 1.3"
  s.add_dependency "mixlib-authentication", "~> 1.4"
  s.add_dependency "mixlib-shellout", "~> 2.0"
  s.add_dependency "mixlib-archive", "~> 0.4"
  s.add_dependency "ohai", "~> 13.0"

  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-ssh", ">= 2.9", "< 5.0"
  s.add_dependency "net-ssh-multi", "~> 1.2", ">= 1.2.1"
  s.add_dependency "net-sftp", "~> 2.1", ">= 2.1.2"
  s.add_dependency "highline", "~> 1.6", ">= 1.6.9"
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "diff-lcs", "~> 1.2", ">= 1.2.4"

  s.add_dependency "chef-zero", ">= 13.0"

  s.add_dependency "plist", "~> 3.2"
  s.add_dependency "iniparse", "~> 1.4"
  s.add_dependency "addressable"
  s.add_dependency "iso8601", "~> 0.9.1"

  # Audit mode requires these, so they are non-developmental dependencies now
  %w{rspec-core rspec-expectations rspec-mocks}.each { |gem| s.add_dependency gem, "~> 3.5" }
  s.add_dependency "rspec_junit_formatter", "~> 0.2.0"
  s.add_dependency "serverspec", "~> 2.7"
  s.add_dependency "specinfra", "~> 2.10"

  s.add_dependency "syslog-logger", "~> 1.6"
  s.add_dependency "uuidtools", "~> 2.1.5"

  s.add_dependency "proxifier", "~> 1.0"

  # v1.10 is needed as a runtime dep now for 'bundler/inline'
  # very deliberately avoiding putting a ceiling on this to avoid depsolver conflicts.
  s.add_dependency "bundler", ">= 1.10"

  s.bindir       = "bin"
  s.executables  = %w{ chef-client chef-solo knife chef-shell chef-apply }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE README.md CONTRIBUTING.md VERSION} + Dir.glob("{distro,lib,lib-backcompat,tasks,acceptance,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) } + Dir.glob("*.gemspec")
end
