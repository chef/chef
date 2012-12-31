#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'tmpdir'
require 'fileutils'
require 'chef_zero/rspec'
require 'chef/config'
require 'json'
require 'support/shared/integration/knife_support'
require 'spec_helper'

module IntegrationSupport
  include ChefZero::RSpec

  def when_the_repository(description, &block)
    context "When the local repository #{description}" do
      before :each do
        raise "Can only create one directory per test" if @repository_dir
        @repository_dir = Dir.mktmpdir('chef_repo')
        Chef::Config.chef_repo_path = @repository_dir
      end

      after :each do
        if @repository_dir
          FileUtils.remove_entry_secure(@repository_dir)
          @repository_dir = nil
        end
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
        FileUtils.mkdir_p(dir) unless dir == '.'
        File.open(filename, 'w') do |file|
          if contents.is_a? Hash
            file.write(JSON.pretty_generate(contents))
          else
            file.write(contents)
          end
        end
      end

      def path_to(relative_path)
        File.expand_path(relative_path, (@parent_path || @repository_dir))
      end

      def self.directory(relative_path, &block)
        before :each do
          directory(relative_path, &block)
        end
      end

      def self.file(relative_path, contents)
        before :each do
          file(relative_path, contents)
        end
      end

      instance_eval(&block)
    end
  end
end
