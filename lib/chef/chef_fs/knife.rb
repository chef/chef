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
require 'chef/chef_fs/parallelizer'
require 'chef/config'

class Chef
  module ChefFS
    class Knife < Chef::Knife
      def self.common_options
        option :repo_mode,
          :long => '--repo-mode MODE',
          :description => "Specifies the local repository layout.  Values: static, everything, hosted_everything.  Default: everything/hosted_everything"

        option :chef_repo_path,
          :long => '--chef-repo-path PATH',
          :description => 'Overrides the location of chef repo. Default is specified by chef_repo_path in the config'

        option :concurrency,
          :long => '--concurrency THREADS',
          :description => 'Maximum number of simultaneous requests to send (default: 10)'
      end

      def configure_chef
        super
        Chef::Config[:repo_mode] = config[:repo_mode] if config[:repo_mode]
        Chef::Config[:concurrency] = config[:concurrency].to_i if config[:concurrency]

        # --chef-repo-path overrides all other paths
        path_variables = %w(acl_path client_path cookbook_path container_path data_bag_path environment_path group_path node_path role_path user_path)
        if config[:chef_repo_path]
          Chef::Config[:chef_repo_path] = config[:chef_repo_path]
          path_variables.each do |variable_name|
            Chef::Config[variable_name.to_sym] = nil
          end
        end

        # Infer chef_repo_path from cookbook_path if not speciifed
        if !Chef::Config[:chef_repo_path]
          if Chef::Config[:cookbook_path]
            Chef::Config[:chef_repo_path] = Array(Chef::Config[:cookbook_path]).flatten.map { |path| File.expand_path('..', path) }
          end
        end

        # Smooth out some (for now) inappropriate defaults set by Chef
        if Chef::Config[:data_bag_path] == Chef::Config.platform_specific_path('/var/chef/data_bags')
          Chef::Config[:data_bag_path] = nil
        end
        if Chef::Config[:node_path] == '/var/chef/node'
          Chef::Config[:node_path] = nil
        end
        if Chef::Config[:role_path] == Chef::Config.platform_specific_path('/var/chef/roles')
          Chef::Config[:role_path] = nil
        end

        # Default to getting *everything* from the server.
        if !Chef::Config[:repo_mode]
          if Chef::Config[:chef_server_url] =~ /\/+organizations\/.+/
            Chef::Config[:repo_mode] = 'hosted_everything'
          else
            Chef::Config[:repo_mode] = 'everything'
          end
        end

        # Infer any *_path variables that are not specified
        if Chef::Config[:chef_repo_path]
          path_variables.each do |variable_name|
            chef_repo_paths = Array(Chef::Config[:chef_repo_path]).flatten
            variable = variable_name.to_sym
            if !Chef::Config[variable]
              # cookbook_path -> cookbooks
              Chef::Config[variable] = chef_repo_paths.map { |path| File.join(path, "#{variable_name[0..-6]}s") }
            end
          end
        end

        Chef::ChefFS::Parallelizer.threads = (Chef::Config[:concurrency] || 10) - 1
      end

      def chef_fs
        @chef_fs ||= Chef::ChefFS::FileSystem::ChefServerRootDir.new("remote", Chef::Config)
      end

      def object_paths
        @object_paths ||= begin
          if !Chef::Config[:chef_repo_path]
            Chef::Log.error("Must specify either chef_repo_path or cookbook_path in Chef config file")
            exit(1)
          end

          result = {}
          case Chef::Config[:repo_mode]
          when 'static'
            object_names = %w(cookbooks data_bags environments roles)
          when 'hosted_everything'
            object_names = %w(acls clients cookbooks containers data_bags environments groups nodes roles)
          else
            object_names = %w(clients cookbooks data_bags environments nodes roles users)
          end
          object_names.each do |object_name|
            variable_name = "#{object_name[0..-2]}_path" # cookbooks -> cookbook_path
            paths = Array(Chef::Config[variable_name]).flatten
            result[object_name] = paths.map { |path| File.expand_path(path) }
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
                absolute_path[realest_path.length,1] =~ /#{PathUtils.regexp_path_separator}/)
              relative_path = Chef::ChefFS::PathUtils::relative_to(absolute_path, realest_path)
              return relative_path == '.' ? "/#{name}" : "/#{name}/#{relative_path}"
            end
          end
        end

        # Check chef_repo_path
        Array(Chef::Config[:chef_repo_path]).flatten.each do |chef_repo_path|
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

      def parallelize(inputs, options = {}, &block)
        Chef::ChefFS::Parallelizer.parallelize(inputs, options, &block)
      end
    end
  end
end
