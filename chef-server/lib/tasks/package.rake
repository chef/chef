require 'rubygems'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = CHEF_SERVER_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  s.add_dependency "merb-core", "~> 1.0.0"
  s.add_dependency "merb-haml", "~> 1.0.0"
  s.add_dependency "merb-assets", "~> 1.0.0"
  s.add_dependency "merb-helpers", "~> 1.0.0"
  %w{ thin haml
    ruby-openid json coderay}.each { |gem| s.add_dependency gem }
  
  s.bindir       = "bin"
  s.executables  = %w( chef-server chef-server-webui )  
  s.files = %w(LICENSE README.rdoc config.ru config-webui.ru) + Dir.glob("{app,bin,config,lib,public}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end



