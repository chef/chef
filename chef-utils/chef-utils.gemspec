# frozen_string_literal: true
lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-utils/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-utils"
  spec.version       = ChefUtils::VERSION
  spec.authors       = ["Chef Software, Inc"]
  spec.email         = ["oss@chef.io"]

  spec.summary       = %q{Basic utility functions for Core Chef Infra development}
  spec.homepage      = "https://github.com/chef/chef/tree/master/chef-utils"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 2.6"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/chef/chef/issues",
    "changelog_uri" => "https://github.com/chef/chef/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/chef/chef/tree/master/chef-utils/README.md",
    "homepage_uri" => "https://github.com/chef/chef/tree/master/chef-utils",
    "source_code_uri" => "https://github.com/chef/chef/tree/master/chef-utils",
  }

  spec.require_paths = ["lib"]

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

  # concurrent-ruby is: 1. lightweight, 2. has zero deps, 3. is external to chef
  # this is used for the parallel_map enumerable extension for lightweight threading
  spec.add_dependency "concurrent-ruby"

  spec.files = %w{Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
end
