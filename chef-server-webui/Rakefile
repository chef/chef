require File.dirname(__FILE__) + '/lib/chef-server-webui/version'

require 'rubygems'
require 'rake/gempackagetask'

begin
  require 'merb-core'
  require 'merb-core/tasks/merb'
rescue LoadError
  STDERR.puts "merb is not installed, merb rake tasks will not be available."
end

GEM_NAME = "chef-server-webui"
AUTHOR = "Opscode"
EMAIL = "chef@opscode.com"
HOMEPAGE = "http://wiki.opscode.com/display/chef"
SUMMARY = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."

spec = eval(File.read("chef-server-webui.gemspec"))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem"
task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{ChefServerWebui::VERSION} --no-rdoc --no-ri}
end

desc "Uninstall the gem"
task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{ChefServerWebui::VERSION} }
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

