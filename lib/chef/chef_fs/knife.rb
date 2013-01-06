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

require 'chef/chef_fs/file_system/chef_server_root_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_root_dir'
require 'chef/chef_fs/file_pattern'
require 'chef/chef_fs/path_utils'
require 'chef/config'

class Chef
  module ChefFS
    class Knife < Chef::Knife
      def self.common_options
        option :repo_mode,
          :long => '--repo-mode MODE',
          :default => "default",
          :description => "Specifies the local repository layout.  Values: default or full"
      end

      def chef_fs
        @chef_fs ||= Chef::ChefFS::FileSystem::ChefServerRootDir.new("remote", Chef::Config, config[:repo_mode])
      end

      def chef_repo_paths
        @chef_repo_paths ||= begin
          result = config_paths(:chef_repo_path)
          if result
            result
          else
            if Chef::Config[:cookbook_path]
              Array(Chef::Config[:cookbook_path]).flatten.map { |path| File.expand_path('..', path) }
            else
              nil
            end
          end
        end
      end

      # Smooth out some inappropriate (for now) variable defaults in Chef.
      def config_paths(name)
        result = case name
        when :data_bag_path
          Chef::Config[name] == Chef::Config.platform_specific_path('/var/chef/data_bags') ? nil : Chef::Config[name]
        when :node_path
          Chef::Config[name] == '/var/chef/node' ? nil : Chef::Config[name]
        when :role_path
          Chef::Config[name] == Chef::Config.platform_specific_path('/var/chef/roles') ? nil : Chef::Config[name]
        else
          Chef::Config[name]
        end
        if result
          Array(result).flatten
        else
          nil
        end
      end

      def object_paths
        @object_paths ||= begin
          result = {}
          if config[:repo_mode] == 'everything'
            object_names = %w(clients cookbooks data_bags environments nodes roles users)
          else
            object_names = %w(cookbooks data_bags environments roles)
          end
          object_names.each do |object_name|
            variable_name = "#{object_name[0..-2]}_path" # cookbooks -> cookbook_path
            paths = config_paths(variable_name.to_sym)
            if !paths
              if !chef_repo_paths
                Chef::Log.error("Must specify either chef_repo_path or #{variable_name} in Chef config file")
                exit(1)
              end
              paths = chef_repo_paths.map { |path| File.join(path, object_name) }
            end
            paths = paths.flatten.map { |path| File.expand_path(path) }
            result[object_name] = paths
          end
          result
        end
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
        absolute_path = Chef::ChefFS::PathUtils.realest_path(File.expand_path(file_path, pwd))

        # Check all object paths (cookbooks_dir, data_bags_dir, etc.)
        object_paths.each_pair do |name, paths|
          paths.each do |path|
            realest_path = Chef::ChefFS::PathUtils.realest_path(path)
            if absolute_path[0,realest_path.length] == realest_path &&
              (absolute_path.length == realest_path.length ||
                absolute_path[realest_path.length] =~ /#{PathUtils.regexp_path_separator}/)
              relative_path = Chef::ChefFS::PathUtils::relative_to(absolute_path, realest_path)
              return relative_path == '.' ? "/#{name}" : "/#{name}/#{relative_path}"
            end
          end
        end

        # Check chef_repo_path
        chef_repo_paths.each do |chef_repo_path|
          realest_chef_repo_path = Chef::ChefFS::PathUtils.realest_path(chef_repo_path)
          if absolute_path == realest_chef_repo_path
            return '/'
          end
        end

        nil
      end

      # The current directory, relative to server root
      def base_path
        @base_path ||= server_path(File.expand_path(Dir.pwd))
      end

      # Print the given server path, relative to the current directory
      def format_path(server_path)
        if base_path && server_path[0,base_path.length] == base_path
          if server_path == base_path
            return "."
          elsif server_path[base_path.length] == "/"
            return server_path[base_path.length + 1, server_path.length - base_path.length - 1]
          elsif base_path == "/" && server_path[0] == "/"
            return server_path[1, server_path.length - 1]
          end
        end
        server_path
      end

      def local_fs
        @local_fs ||= Chef::ChefFS::FileSystem::ChefRepositoryFileSystemRootDir.new(object_paths)
      end

      def pattern_args
        @pattern_args ||= pattern_args_from(name_args)
      end

      def pattern_args_from(args)
        # TODO support absolute file paths and not just patterns?  Too much?
        # Could be super useful in a world with multiple repo paths
        args.map do |arg|
          if !base_path && !PathUtils.is_absolute?(arg)
            ui.error("Attempt to use relative path '#{arg}' when current directory is outside the repository path")
            exit(1)
          end
          Chef::ChefFS::FilePattern::relative_to(base_path, arg)
        end
      end

    end
  end
end
