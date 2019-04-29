# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-bin/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-bin"
  spec.version       = ChefBin::VERSION
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@chef.io"]

  spec.summary       = %q{Chef-branded binstubs for chef-client}
  spec.homepage      = "https://github.com/chef/chef"
  spec.license       = "Apache-2.0"

  spec.require_paths = ["lib"]

  spec.add_dependency "chef", "= #{ChefBin::VERSION}"
  spec.add_development_dependency "rake"

  spec.files = %w{Gemfile Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.bindir = "bin"
  spec.executables = %w{ chef-apply chef-client chef-resource-inspector chef-service-manager chef-shell chef-solo chef-windows-service }
end
