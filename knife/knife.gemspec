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

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency "chef-config", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "chef-utils", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "chef", ">= #{Chef::Knife::VERSION.split(".").first}"
  s.add_dependency "train-core", "~> 3.2", ">= 3.2.28" # 3.2.28 fixes sudo prompts. See https://github.com/chef/chef/pull/9635
  s.add_dependency "train-winrm", ">= 0.2.5"
  s.add_dependency "license-acceptance", ">= 1.0.5", "< 3"
  s.add_dependency "mixlib-cli", ">= 2.1.1", "< 3.0"
  s.add_dependency "mixlib-archive", ">= 0.4", "< 2.0"
  s.add_dependency "ohai", "~> 17.0"
  s.add_dependency "ffi", ">= 1.15" # 1.14 versions are broken on i386 windows
  s.add_dependency "ffi-yajl", "~> 2.2"
  s.add_dependency "net-ssh", ">= 5.1", "< 7"
  s.add_dependency "net-ssh-multi", "~> 1.2", ">= 1.2.1"
  s.add_dependency "ed25519", "~> 1.2" # ed25519 ssh key support
  s.add_dependency "bcrypt_pbkdf", "~> 1.1" # ed25519 ssh key support
  s.add_dependency "x25519" # ed25519 KEX module
  s.add_dependency "highline", ">= 1.6.9", "< 3" # Used in UI to present a list, no other usage.

  s.add_dependency "tty-prompt", "~> 0.21" # knife ui.ask prompt
  s.add_dependency "tty-screen", "~> 0.6" # knife list
  s.add_dependency "tty-table", "~> 0.11" # knife render table output.
  s.add_dependency "pastel" # knife ui.color
  s.add_dependency "erubis", "~> 2.7"
  s.add_dependency "chef-vault" # knife vault

  s.add_development_dependency "chefstyle"

  s.bindir       = "bin"
  s.executables  = %w{ knife }

  s.require_paths = %w{ lib }
  s.files = %w{Gemfile Rakefile LICENSE knife.gemspec} +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/chef/chef/issues",
    "changelog_uri"     => "https://github.com/chef/chef/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://docs.chef.io/",
    "homepage_uri"      => "https://www.chef.io",
    "mailing_list_uri"  => "https://discourse.chef.io/",
    "source_code_uri"   => "https://github.com/chef/chef/",
  }
end
