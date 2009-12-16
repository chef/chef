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
  
  %w{ merb-core merb-haml merb-assets
    merb-helpers thin haml
    ruby-openid json coderay}.each { |gem| s.add_dependency gem }
  
  s.bindir       = "bin"
  s.executables  = %w( chef-server chef-indexer )  
  s.files = %w(LICENSE README.rdoc config.ru) + Dir.glob("{app,bin,config,lib,public}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end



