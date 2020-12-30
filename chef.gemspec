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

  s.required_ruby_version = ">= 2.6.0"

  s.add_dependency "chef-config", "= #{Chef::VERSION}"
  s.add_dependency "chef-utils", "= #{Chef::VERSION}"
  s.add_dependency "train-core", "~> 3.2", ">= 3.2.28" # 3.2.28 fixes sudo prompts. See https://github.com/chef/chef/pull/9635
  s.add_dependency "train-winrm", ">= 0.2.5"

  s.add_dependency "license-acceptance", ">= 1.0.5", "< 3"
  s.add_dependency "mixlib-cli", ">= 2.1.1", "< 3.0"
  s.add_dependency "mixlib-log", ">= 2.0.3", "< 4.0"
  s.add_dependency "mixlib-authentication", ">= 2.1", "< 4"
  s.add_dependency "mixlib-shellout", ">= 3.1.1", "< 4.0"
  s.add_dependency "mixlib-archive", ">= 0.4", "< 2.0"
  s.add_dependency "ohai", "~> 17.0"
  s.add_dependency "inspec-core", "~> 4.23"

  s.add_dependency "ffi", ">= 1.9.25"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-ssh", ">= 5.1", "< 7"
  s.add_dependency "net-ssh-multi", "~> 1.2", ">= 1.2.1"
  s.add_dependency "net-sftp", ">= 2.1.2", "< 4.0"
  s.add_dependency "ed25519", "~> 1.2" # ed25519 ssh key support
  s.add_dependency "bcrypt_pbkdf", "= 1.1.0.rc1" # ed25519 ssh key support
  s.add_dependency "highline", ">= 1.6.9", "< 3"
  s.add_dependency "tty-prompt", "~> 0.21" # knife ui.ask prompt
  s.add_dependency "tty-screen", "~> 0.6" # knife list
  s.add_dependency "tty-table", "~> 0.11" # knife render table output.
  s.add_dependency "pastel" # knife ui.color
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "diff-lcs", ">= 1.2.4", "< 1.4.0" # 1.4 breaks output
  s.add_dependency "ffi-libarchive", "~> 1.0", ">= 1.0.3"
  s.add_dependency "chef-zero", ">= 14.0.11"
  s.add_dependency "chef-vault"

  s.add_dependency "plist", "~> 3.2"
  s.add_dependency "iniparse", "~> 1.4"
  s.add_dependency "addressable"
  s.add_dependency "syslog-logger", "~> 1.6"
  s.add_dependency "uuidtools", "~> 2.1.5"

  s.add_dependency "proxifier", "~> 1.0"

  s.bindir       = "bin"
  s.executables  = %w{ knife }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE README.md} +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) } +
    Dir.glob("*.gemspec") +
    Dir.glob("tasks/rspec.rb")
end
