#
# Author:: John Keiser (<jkeiser@chef.io>)
# Author:: Ho-Sheng Hsiao (<hosh@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "tmpdir"
require "fileutils"
require "chef/config"
require "chef/json_compat"
require "chef/server_api"
require "cheffish/rspec/chef_run_support"

module Cheffish
  class BasicChefClient
    def_delegators :@run_context, :before_notifications
  end
end

module IntegrationSupport
  include ChefZero::RSpec

  def self.included(includer_class)
    includer_class.extend(Cheffish::RSpec::ChefRunSupport)
    includer_class.extend(ClassMethods)
  end

  module ClassMethods
    include ChefZero::RSpec

    def when_the_repository(desc, *tags, &block)
      context("when the chef repo #{desc}", *tags) do
        before :each do
          raise "Can only create one directory per test" if @repository_dir

          @repository_dir = Dir.mktmpdir("chef_repo")
          Chef::Config.chef_repo_path = @repository_dir
          %w{client cookbook data_bag environment node role user}.each do |object_name|
            Chef::Config.delete("#{object_name}_path".to_sym)
          end
        end

        after :each do
          if @repository_dir
            begin
              # TODO: "force" actually means "silence all exceptions". this
              # silences a weird permissions error on Windows that we should track
              # down, but for now there's no reason for it to blow up our CI.
              FileUtils.remove_entry_secure(@repository_dir, force = ChefUtils.windows?)
            ensure
              @repository_dir = nil
            end
          end
          Dir.chdir(@old_cwd) if @old_cwd
        end

        module_eval(&block)
      end
    end
  end

  def api
    Chef::ServerAPI.new
  end

  def directory(relative_path, &block)
    old_parent_path = @parent_path
    @parent_path = path_to(relative_path)
    FileUtils.mkdir_p(@parent_path)
    instance_eval(&block) if block
    @parent_path = old_parent_path
  end

  def file(relative_path, contents)
    filename = path_to(relative_path)
    dir = File.dirname(filename)
    FileUtils.mkdir_p(dir) unless dir == "."
    File.open(filename, "w") do |file|
      raw = case contents
            when Hash, Array
              Chef::JSONCompat.to_json_pretty(contents)
            else
              contents
            end
      file.write(raw)
    end
  end

  def symlink(relative_path, relative_dest)
    filename = path_to(relative_path)
    dir = File.dirname(filename)
    FileUtils.mkdir_p(dir) unless dir == "."
    dest_filename = path_to(relative_dest)
    File.symlink(dest_filename, filename)
  end

  def path_to(relative_path)
    File.expand_path(relative_path, (@parent_path || @repository_dir))
  end

  def cb_metadata(name, version, extra_text = "")
    "name #{name.inspect}; version #{version.inspect}#{extra_text}"
  end

  def cwd(relative_path)
    @old_cwd = Dir.pwd
    Dir.chdir(path_to(relative_path))
  end
end
