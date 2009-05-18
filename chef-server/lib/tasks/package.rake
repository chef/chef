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
  
  s.add_dependency "stomp"
  s.add_dependency "stompserver"
  s.add_dependency "ferret"
  s.add_dependency "merb-core"
  s.add_dependency "merb-haml"
  s.add_dependency "merb-assets"
  s.add_dependency "merb-helpers"
  s.add_dependency "mongrel"
  s.add_dependency "haml"
  s.add_dependency "ruby-openid"
  s.add_dependency "json"
  s.add_dependency "syntax"
  
  s.bindir       = "bin"
  s.executables  = %w( chef-server chef-indexer )  
  s.files = %w(LICENSE README.rdoc Rakefile) + 
    [ "README.txt",
      "LICENSE",
      "NOTICE",
      "config.ru",
      "{app}/**/*",
      "{config}/**/*",
      "{contrib}/**/*",
      "{doc}/**/*",
      "{lib}/**/*",
      "{log}/**/*",
      "{merb}/**/*",
      "{public}/**/*",
      "{slices}/**/*",
      "{spec}/**/*",
      "{tasks}/**/*",].inject([]) { |m,dir| m << Dir.glob(dir) }.flatten
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end



