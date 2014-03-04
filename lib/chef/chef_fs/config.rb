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

require 'chef/log'
require 'chef/chef_fs/path_utils'

class Chef
  module ChefFS
    #
    # Helpers to take Chef::Config and create chef_fs and local_fs from it
    #
    class Config
      def initialize(chef_config = Chef::Config, cwd = Dir.pwd, options = {})
        @chef_config = chef_config
        @cwd = cwd
        @cookbook_version = options[:cookbook_version]

        # Default to getting *everything* from the server.
        if !@chef_config[:repo_mode]
          if @chef_config[:chef_server_url] =~ /\/+organizations\/.+/
            @chef_config[:repo_mode] = 'hosted_everything'
          else
            @chef_config[:repo_mode] = 'everything'
          end
        end
      end

      attr_reader :chef_config
      attr_reader :cwd
      attr_reader :cookbook_version

      def chef_fs
        @chef_fs ||= create_chef_fs
      end

      def create_chef_fs
        require 'chef/chef_fs/file_system/chef_server_root_dir'
        Chef::ChefFS::FileSystem::ChefServerRootDir.new("remote", @chef_config, :cookbook_version => @cookbook_version)
      end

      def local_fs
        @local_fs ||= create_local_fs
      end

      def create_local_fs
        require 'chef/chef_fs/file_system/chef_repository_file_system_root_dir'
        Chef::ChefFS::FileSystem::ChefRepositoryFileSystemRootDir.new(object_paths)
      end

      # Returns the given real path's location relative to the server root.
      #
      # If chef_repo is /home/jkeiser/chef_repo,
      # and pwd is /home/jkeiser/chef_repo/cookbooks,
      # server_path('blah') == '/cookbooks/blah'
      # server_path('../roles/blah.json') == '/roles/blah'
      # server_path('../../readme.txt') == nil
      # server_path('*/*ab*') == '/cookbooks/*/*ab*'
      # server_path('/home/jkeiser/chef_repo/cookbooks/blah') == '/cookbooks/blah'
      # server_path('/home/*/chef_repo/cookbooks/blah') == nil
      #
      # If there are multiple paths (cookbooks, roles, data bags, etc. can all
      # have separate paths), and cwd+the path reaches into one of them, we will
      # return a path relative to that.  Otherwise we will return a path to
      # chef_repo.
      #
      # Globs are allowed as well, but globs outside server paths are NOT
      # (presently) supported.  See above examples.  TODO support that.
      #
      # If the path does not reach into ANY specified directory, nil is returned.
      def server_path(file_path)
        pwd = File.expand_path(Dir.pwd)
        absolute_pwd = Chef::ChefFS::PathUtils.realest_path(File.expand_path(file_path, pwd))

        # Check all object paths (cookbooks_dir, data_bags_dir, etc.)
        object_paths.each_pair do |name, paths|
          paths.each do |path|
            realest_path = Chef::ChefFS::PathUtils.realest_path(path)
            if PathUtils.descendant_of?(absolute_pwd, realest_path)
              relative_path = Chef::ChefFS::PathUtils::relative_to(absolute_pwd, realest_path)
              return relative_path == '.' ? "/#{name}" : "/#{name}/#{relative_path}"
            end
          end
        end

        # Check chef_repo_path
        Array(@chef_config[:chef_repo_path]).flatten.each do |chef_repo_path|
          realest_chef_repo_path = Chef::ChefFS::PathUtils.realest_path(chef_repo_path)
          if absolute_pwd == realest_chef_repo_path
            return '/'
          end
        end

        nil
      end

      # The current directory, relative to server root
      def base_path
        @base_path ||= begin
          if @chef_config[:chef_repo_path]
            server_path(File.expand_path(@cwd))
          else
            nil
          end
        end
      end

      # Print the given server path, relative to the current directory
      def format_path(entry)
        server_path = entry.path
        if base_path && server_path[0,base_path.length] == base_path
          if server_path == base_path
            return "."
          elsif server_path[base_path.length,1] == "/"
            return server_path[base_path.length + 1, server_path.length - base_path.length - 1]
          elsif base_path == "/" && server_path[0,1] == "/"
            return server_path[1, server_path.length - 1]
          end
        end
        server_path
      end

      private

      def object_paths
        @object_paths ||= begin
          result = {}
          case @chef_config[:repo_mode]
          when 'static'
            object_names = %w(cookbooks data_bags environments roles)
          when 'hosted_everything'
            object_names = %w(acls clients cookbooks containers data_bags environments groups nodes roles)
          else
            object_names = %w(clients cookbooks data_bags environments nodes roles users)
          end
          object_names.each do |object_name|
            variable_name = "#{object_name[0..-2]}_path" # cookbooks -> cookbook_path
            paths = Array(@chef_config[variable_name]).flatten
            result[object_name] = paths.map { |path| File.expand_path(path) }
          end
          result
        end
      end
    end
  end
end
