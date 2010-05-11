require 'rubygems'
require 'rake/gempackagetask'

require 'merb-core'
require 'merb-core/tasks/merb'

GEM_NAME = "chef-server-webui"
CHEF_SERVER_VERSION="0.8.16"
AUTHOR = "Opscode"
EMAIL = "chef@opscode.com"
HOMEPAGE = "http://wiki.opscode.com/display/chef"
SUMMARY = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
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
  s.add_dependency "merb-slices", "~> 1.0.0"
  s.add_dependency "merb-assets", "~> 1.0.0"
  s.add_dependency "merb-helpers", "~> 1.0.0"
  s.add_dependency "merb-haml", "~> 1.0.0"
  s.add_dependency "merb-param-protection", "~> 1.0.0"

  s.add_dependency "json", "<= 1.4.2"

  %w{thin haml ruby-openid coderay}.each { |g| s.add_dependency g}

  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc Rakefile config.ru) + Dir.glob("{bin,config,lib,spec,app,public,stubs}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem"
task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{CHEF_SERVER_VERSION} --no-rdoc --no-ri}
end

desc "Uninstall the gem"
task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{CHEF_SERVER_VERSION} }
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

