$:.unshift(File.dirname(__FILE__) + "/lib")
require_relative "lib/chef/knife/version"

Gem::Specification.new do |s|
  s.name = "knife"
  s.version = Chef::Knife::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["LICENSE"]
  s.summary = "The knife CLI for Chef Infra."
  s.description = s.summary
  s.license = "Apache-2.0"
  s.author = "Adam Jacob"
  s.email = "adam@chef.io" # These seem a bit out of date, and this address probably doesn't go anywhere anymore?
  s.homepage = "https://www.chef.io"

  s.required_ruby_version = ">= 3.1.0"

  s.add_dependency "chef-config", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "chef-utils", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "chef", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "train-core", "~> 3.13", ">= 3.13.4" # Updated to be compatible with InSpec 7
  s.add_dependency "train-winrm", ">= 0.2.17"
  s.add_dependency "license-acceptance", ">= 1.0.5", "< 3"
  s.add_dependency "mixlib-cli", ">= 2.1.1", "< 3.0"
  s.add_dependency "mixlib-archive", ">= 0.4", "< 2.0"
  s.add_dependency "ohai", "~> 19.0"
  s.add_dependency "ffi", ">= 1.15", "< 1.18.0"
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-ssh", ">= 5.1", "< 8"
  s.add_dependency "net-ssh-multi", "~> 1.2", ">= 1.2.1"
  s.add_dependency "bcrypt_pbkdf", "~> 1.1" # ed25519 ssh key support
  # disabling this until we get get it to compile on RHEL 7
  # s.add_dependency "x25519", ">= 1.0.9" # ed25519 KEX module. 1.0.9+ required to resolve sigill failures
  s.add_dependency "highline", ">= 1.6.9", "< 3" # Used in UI to present a list, no other usage.
  s.add_dependency "abbrev"

  s.add_dependency "tty-prompt", "~> 0.21" # knife ui.ask prompt
  s.add_dependency "tty-screen", "~> 0.6" # knife list
  s.add_dependency "tty-table", "~> 0.11" # knife render table output.
  s.add_dependency "pastel" # knife ui.color
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "chef-vault" # knife vault

  s.add_development_dependency "cookstyle", ">= 7.32.8"

  s.add_dependency "proxifier2", "~> 1.1"

  s.bindir       = "bin"
  s.executables  = %w{ knife }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE knife.gemspec} +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/chef/chef/issues",
    "changelog_uri"     => "https://github.com/chef/chef/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://docs.chef.io/",
    "homepage_uri"      => "https://www.chef.io",
    "mailing_list_uri"  => "https://discourse.chef.io/",
    "source_code_uri"   => "https://github.com/chef/chef/",
  }
end
