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

VERSION = IO.read(File.expand_path("../VERSION", __FILE__)).strip

require 'rubygems'
require 'chef-config/package_task'
require 'rdoc/task'
require_relative 'tasks/rspec'
require_relative 'tasks/external_tests'
require_relative 'tasks/maintainers'

ChefConfig::PackageTask.new(File.expand_path('..', __FILE__), 'Chef') do |package|
  package.component_paths = ['chef-config']
  package.generate_version_class = true
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

