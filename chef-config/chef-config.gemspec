lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-config/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-config"
  spec.version       = ChefConfig::VERSION
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@chef.io"]

  spec.summary       = %q{Chef Infra's default configuration and config loading library}
  spec.homepage      = "https://github.com/chef/chef"
  spec.license       = "Apache-2.0"

  spec.required_ruby_version = ">= 2.6"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/chef/chef/issues",
    "changelog_uri" => "https://github.com/chef/chef/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/chef/chef/tree/master/chef-config/README.md",
    "homepage_uri" => "https://github.com/chef/chef/tree/master/chef-config",
    "source_code_uri" => "https://github.com/chef/chef/tree/master/chef-config",
  }

  spec.require_paths = ["lib"]

  spec.add_dependency "chef-utils", "= #{ChefConfig::VERSION}"
  spec.add_dependency "mixlib-shellout", ">= 2.0", "< 4.0"
  spec.add_dependency "mixlib-config", ">= 2.2.12", "< 4.0"
  spec.add_dependency "fuzzyurl"
  spec.add_dependency "addressable"
  spec.add_dependency "tomlrb", "~> 1.2"

  spec.files = %w{Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.bindir        = "bin"
  spec.executables   = []
end
