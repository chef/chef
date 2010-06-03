#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require File.dirname(__FILE__) + '/lib/chef/solr/version'

require 'rubygems'
require 'rake'
require 'rake/gempackagetask'

GEM_NAME = "chef-solr"

spec = Gem::Specification.new do |gem|
  gem.name = "chef-solr"
  gem.version = Chef::Solr::VERSION
  gem.summary = %Q{Search indexing for Chef}
  gem.email = "adam@opscode.com"
  gem.homepage = "http://wiki.opscode.com/display/chef"
  gem.authors = ["Adam Jacob"]
  gem.add_dependency "libxml-ruby", ">=1.1.3"
  gem.add_dependency "uuidtools", ">=2.0.0"
  gem.add_dependency "chef", Chef::Solr::VERSION
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  gem.executables = [ 'chef-solr', 'chef-solr-indexer', 'chef-solr-rebuild' ]
  gem.files = [
    "README.rdoc",
    "Rakefile"
  ]
  gem.files = %w{ README.rdoc Rakefile LICENSE} + Dir.glob("{bin,lib,solr,spec}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem"
task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{Chef::Solr::VERSION} --no-rdoc --no-ri}
end

desc "Uninstall the gem"
task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{Chef::Solr::VERSION} }
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end



begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
    spec.spec_opts = ['--options', File.expand_path(File.dirname(__FILE__) + '/spec/spec.opts')]
  end

  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov = true
  end

  begin
    require 'cucumber/rake/task'
    Cucumber::Rake::Task.new(:features)
  rescue LoadError
    task :features do
      abort "Cucumber is not available. In order to run features, you must: sudo gem install cucumber"
    end
  end

  task :default => :spec
rescue LoadError
  STDERR.puts "\n*** rspec not available. (sudo) gem install rspec to run unit tests. ***\n\n"
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = Chef::Solr::VERSION
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "chef-solr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

