#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2008-2019, Chef Software Inc.
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

require_relative "tasks/rspec"
require_relative "tasks/dependencies"
require_relative "tasks/announce"

ENV["CHEF_LICENSE"] = "accept-no-persist"

# hack the chef-config install to run before the traditional install task
task :super_install do
  chef_config_path = ::File.join(::File.dirname(__FILE__), "chef-config")
  Dir.chdir(chef_config_path)
  sh("rake install")
end

task install: :super_install

# make sure we build the correct gemspec on windows
gemspec = Gem.win_platform? ? "chef-universal-mingw32" : "chef"
Bundler::GemHelper.install_tasks name: gemspec

# this gets appended to the normal bundler install helper
task :install do
  chef_bin_path = ::File.join(::File.dirname(__FILE__), "chef-bin")
  Dir.chdir(chef_bin_path)
  sh("rake install:force")
end

task :pedant, :chef_zero_spec

task :build_eventlog do
  Dir.chdir "ext/win32-eventlog/" do
    system "rake build"
  end
end

task :register_eventlog do
  Dir.chdir "ext/win32-eventlog/" do
    system "rake register"
  end
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle/rubocop is not available. bundle install first to make sure all dependencies are installed."
end

begin
  require "yard"
  DOC_FILES = [ "spec/tiny_server.rb", "lib/**/*.rb" ].freeze

  YARD::Rake::YardocTask.new(:docs) do |t|
    t.files = DOC_FILES
    t.options = ["--format", "html"]
  end
rescue LoadError
  puts "yard is not available. bundle install first to make sure all dependencies are installed."
end
