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

require File.dirname(__FILE__) + '/lib/chef/version'

require 'rubygems'
require 'rubygems/package_task'
require 'rdoc/task'
require './tasks/rspec.rb'

GEM_NAME = "chef"

Dir[File.expand_path("../*gemspec", __FILE__)].reverse.each do |gemspec_path|
  gemspec = eval(IO.read(gemspec_path))
  Gem::PackageTask.new(gemspec).define
end

task :install => :package do
  sh %{gem install pkg/#{GEM_NAME}-#{Chef::VERSION}.gem --no-rdoc --no-ri}
end

task :uninstall do
  sh %{gem uninstall #{GEM_NAME} -x -v #{Chef::VERSION} }
end

desc "Build it, tag it and ship it"
task :ship => [:clobber_package, :gem] do
  sh("git tag #{Chef::VERSION}")
  sh("git push opscode --tags")
  Dir[File.expand_path("../pkg/*.gem", __FILE__)].reverse.each do |built_gem|
    sh("gem push #{built_gem}")
  end
end

task :pedant do
  require File.expand_path('spec/support/pedant/run_pedant')
end

task :build_eventlog do
  Dir.chdir 'ext/win32-eventlog/' do
    system 'rake build'
  end
end

task :register_eventlog do
  Dir.chdir 'ext/win32-eventlog/' do
    system 'rake register'
  end
end

begin
  require 'yard'
  DOC_FILES = [ "README.rdoc", "LICENSE", "spec/tiny_server.rb", "lib/**/*.rb" ]
  namespace :yard do
    desc "Create YARD documentation"

    YARD::Rake::YardocTask.new(:html) do |t|
      t.files = DOC_FILES
      t.options = ['--format', 'html']
    end
  end

rescue LoadError
  puts "yard is not available. (sudo) gem install yard to generate yard documentation."
end
