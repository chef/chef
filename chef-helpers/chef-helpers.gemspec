# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-helpers/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-helpers"
  spec.version       = ChefHelpers::VERSION
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@chef.io"]

  spec.summary       = %q{Basic helpers for Core Chef development}
  spec.homepage      = "https://github.com/chef/chef"
  spec.license       = "Apache-2.0"

  spec.require_paths = ["lib"]

  # FIXME: helpful screaming at people to not add deps to any other chef-ecosystem gems

  spec.add_development_dependency "rake"

  %w{rspec-core rspec-expectations rspec-mocks}.each do |rspec|
    spec.add_development_dependency(rspec, "~> 3.2")
  end

  spec.files = %w{Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  spec.bindir        = "bin"
  spec.executables   = []
end
