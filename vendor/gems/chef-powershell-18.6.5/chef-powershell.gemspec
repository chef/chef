# frozen_string_literal: true
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
bin = File.expand_path("bin", __dir__)
$LOAD_PATH.unshift(bin) unless $LOAD_PATH.include?(bin)
require "chef-powershell/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-powershell"
  spec.version       = ChefPowerShellModule::VERSION
  spec.authors       = ["Chef Software, Inc"]
  spec.email         = ["oss@chef.io"]

  spec.summary       = %q{External Chef module for accessing and utilizing PowerShell}
  spec.homepage      = "https://github.com/chef/chef-powershell-shim"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "ffi", "~> 1.15"
  spec.add_dependency "ffi-yajl", "~> 2.4"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/chef/chef/issues",
    "changelog_uri" => "https://github.com/chef/chef-powershell-shim/CHANGELOG.md",
    "documentation_uri" => "https://github.com/chef/chef-powershell-shim/chef-powershell/README.md",
    "homepage_uri" => "https://github.com/chef/chef/tree/18-Stable/chef-powershell",
    "source_code_uri" => "https://github.com/chef/chef-powershell-shim/chef-powershell",
  }

  spec.require_paths = %w{lib bin}

  #
  # NOTE: DO NOT ADD RUNTIME DEPS TO OTHER CHEF ECOSYSTEM GEMS
  # (e.g. chef, ohai, mixlib-anything, ffi-yajl, and IN PARTICULAR NOT chef-config)
  #
  # This is so that this set of common code can be reused in any other library without
  # creating circular dependencies.  If you find yourself wanting to do that you probably
  # have a helper that should go into the library you want to declare a dependency on,
  # or you need to create another gem that is not this one.  You may also want to rub some
  # dependency injection on your API to invert things so that you don't have to take
  # a dependency on the thing you need (i.e. allow injecting a hash-like thing instead of taking
  # a dep on mixlib-config and then require the consumer to wire up chef-config to your
  # API).  Same for mixlib-log and Chef::Log in general.
  #
  # ABSOLUTELY NO EXCEPTIONS
  #
  spec.bindir        = "bin"
  spec.executables   = []
  spec.files = %w{Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec,bin,ext}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  # Post-install extension to copy DLL files to chef/embedded/bin
  spec.extensions = ["ext/chef-powershell/extconf.rb"]
end
