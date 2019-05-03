$:.unshift(File.dirname(__FILE__) + "/lib")
require "chef/version"

Gem::Specification.new do |s|
  s.name = "chef"
  s.version = Chef::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["README.md", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io"
  s.homepage = "https://www.chef.io"

  s.required_ruby_version = ">= 2.5.0"

  s.add_dependency "chef-config", "= #{Chef::VERSION}"
  s.add_dependency "train-core", "~> 2.0", ">= 2.0.12"

  s.add_dependency "license-acceptance", "~> 1.0"
  s.add_dependency "mixlib-cli", ">= 1.7", "< 3.0"
  s.add_dependency "mixlib-log", ">= 2.0.3", "< 4.0"
  s.add_dependency "mixlib-authentication", "~> 2.1"
  s.add_dependency "mixlib-shellout", ">= 2.4", "< 4.0"
  s.add_dependency "mixlib-archive", ">= 0.4", "< 2.0"
  s.add_dependency "ohai", "~> 15.0"

  s.add_dependency "ffi", "~> 1.9", ">= 1.9.25"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-ssh", ">= 4.2", "< 6"
  s.add_dependency "net-ssh-multi", "~> 1.2", ">= 1.2.1"
  s.add_dependency "net-sftp", "~> 2.1", ">= 2.1.2"
  s.add_dependency "ed25519", "~> 1.2" # ed25519 ssh key support
  s.add_dependency "bcrypt_pbkdf", "~> 1.0" # ed25519 ssh key support
  s.add_dependency "highline", ">= 1.6.9", "< 2"
  s.add_dependency "tty-screen", "~> 0.6" # knife list
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "diff-lcs", "~> 1.2", ">= 1.2.4"
  s.add_dependency "ffi-libarchive"
  s.add_dependency "chef-zero", ">= 14.0.11"
  s.add_dependency "plist", "~> 3.2"
  s.add_dependency "iniparse", "~> 1.4"
  s.add_dependency "addressable"
  s.add_dependency "syslog-logger", "~> 1.6"
  s.add_dependency "uuidtools", "~> 2.1.5"

  s.add_dependency "proxifier", "~> 1.0"

  # v1.10 is needed as a runtime dep now for 'bundler/inline'
  # very deliberately avoiding putting a ceiling on this to avoid depsolver conflicts.
  s.add_dependency "bundler", ">= 1.10"

  s.bindir       = "bin"
  s.executables  = %w{ knife }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE README.md} + Dir.glob("{lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) } + Dir.glob("*.gemspec")
end
