# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-config/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-config"
  spec.version       = ChefConfig::VERSION
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@chef.io"]

  spec.summary       = %q{Chef's default configuration and config loading}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "Apache-2.0"

  spec.require_paths = ["lib"]

  spec.add_dependency "mixlib-shellout", "~> 2.0"
  spec.add_dependency "mixlib-config", "~> 2.0"

  spec.add_development_dependency "rake", "~> 10.0"

  %w(rspec-core rspec-expectations rspec-mocks).each do |rspec|
    spec.add_development_dependency(rspec, "~> 3.2")
  end

  spec.files = %w(Rakefile LICENSE README.md) +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }

  spec.bindir        = "bin"
  spec.executables   = []
end
