#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright, Chef Software Inc.
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

# we need this to resolve files required by lib/chef/dist
$LOAD_PATH.unshift(File.expand_path("chef-config/lib", __dir__))

begin
  require_relative "tasks/rspec"
  require_relative "tasks/dependencies"
  require_relative "tasks/docs"
  require_relative "tasks/spellcheck"
  require_relative "chef-utils/lib/chef-utils/dist" unless defined?(ChefUtils::Dist)
rescue LoadError => e
  puts "Skipping missing rake dep: #{e}"
end

require "bundler/gem_helper"

ENV["CHEF_LICENSE"] = "accept-no-persist"

namespace :pre_install do
  desc "Runs 'rake install' for the gems that live in subdirectories in this repo"
  task :install_gems_from_dirs do
    %w{chef-utils chef-config}.each do |gem|
      path = ::File.join(::File.dirname(__FILE__), gem)
      Dir.chdir(path) do
        system "rake install"
      end
    end
  end

  desc "Renders the powershell extensions with distro flavoring"
  task :render_powershell_extension do
    require "erb"
    template_file = ::File.join(::File.dirname(__FILE__), "distro", "templates", "powershell", "chef", "chef.psm1.erb")
    psm1_path = ::File.join(::File.dirname(__FILE__), "distro", "powershell", "chef")
    FileUtils.mkdir_p psm1_path
    template = ERB.new(IO.read(template_file))
    chef_psm1 = template.result
    File.open(::File.join(psm1_path, "chef.psm1"), "w") { |f| f.write(chef_psm1) }
  end

  task all: ["pre_install:install_gems_from_dirs", "pre_install:render_powershell_extension"]
end

# hack in all the preinstall tasks to occur before the traditional install task
task install: "pre_install:all"
# make sure we build the correct gemspec on windows
gemspec = Gem.win_platform? ? "chef-universal-mingw-ucrt" : "chef"

Bundler::GemHelper.install_tasks name: gemspec

# this gets appended to the normal bundler install helper
task :install do
  chef_bin_path = ::File.join(::File.dirname(__FILE__), "chef-bin")
  Dir.chdir(chef_bin_path) do
    system "rake install:force"
  end
end

namespace :install do
  task local: "pre_install:all"

  task :local do
    chef_bin_path = ::File.join(::File.dirname(__FILE__), "chef-bin")
    Dir.chdir(chef_bin_path) do
      system "rake install:local"
    end
  end
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
