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
require 'rubygems/package_task'
require '../chef/tasks/rspec.rb'

spec = eval(File.read(File.dirname(__FILE__) + "/chef-solr.gemspec"))

desc "Create solr archives"
task :tar_solr do
  %w{solr-home solr-jetty}.each do |tar|
    Dir.chdir(File.dirname(__FILE__) + "/solr/#{tar}") { sh "tar cvzf ../#{tar}.tar.gz *" }
  end
end

task :gem => :tar_solr

Gem::PackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Install the gem"
task :install => :package do
  sh %{gem install pkg/chef-solr-#{Chef::Solr::VERSION} --no-rdoc --no-ri}
end

desc "Uninstall the gem"
task :uninstall do
  sh %{gem uninstall chef-solr -x -v #{Chef::Solr::VERSION} }
end

require 'rdoc/task'
RDoc::Task.new do |rdoc|
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

task :default => :spec
