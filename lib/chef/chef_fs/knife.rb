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

require 'chef/knife'

class Chef
  module ChefFS
    class Knife < Chef::Knife
      # Workaround for CHEF-3932
      def self.deps
        super do
          require 'chef/config'
          require 'chef/chef_fs/parallelizer'
          require 'chef/chef_fs/config'
          require 'chef/chef_fs/file_pattern'
          require 'chef/chef_fs/path_utils'
          yield
        end
      end

      def self.inherited(c)
        super
        # Ensure we always get to do our includes, whether subclass calls deps or not
        c.deps do
        end

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
        if config[:chef_repo_path]
          Chef::Config[:chef_repo_path] = config[:chef_repo_path]
          Chef::ChefFS::Config::PATH_VARIABLES.each do |variable_name|
            Chef::Config[variable_name.to_sym] = chef_repo_paths.map { |path| File.join(path, "#{variable_name[0..-6]}s") }
          end
        end

        @chef_fs_config = Chef::ChefFS::Config.new(Chef::Config)

        Chef::ChefFS::Parallelizer.threads = (Chef::Config[:concurrency] || 10) - 1
      end

      def chef_fs
        @chef_fs_config.chef_fs
      end

      def create_chef_fs
        @chef_fs_config.create_chef_fs
      end

      def local_fs
        @chef_fs_config.local_fs
      end

      def create_local_fs
        @chef_fs_config.create_local_fs
      end

      def pattern_args
        @pattern_args ||= pattern_args_from(name_args)
      end

      def pattern_args_from(args)
        # TODO support absolute file paths and not just patterns?  Too much?
        # Could be super useful in a world with multiple repo paths
        args.map do |arg|
          if !@chef_fs_config.base_path && !Chef::ChefFS::PathUtils.is_absolute?(arg)
            # Check if chef repo path is specified to give a better error message
            @chef_fs_config.require_chef_repo_path
            ui.error("Attempt to use relative path '#{arg}' when current directory is outside the repository path")
            exit(1)
          end
          Chef::ChefFS::FilePattern.relative_to(@chef_fs_config.base_path, arg)
        end
      end

      def format_path(entry)
        @chef_fs_config.format_path(entry)
      end

      def parallelize(inputs, options = {}, &block)
        Chef::ChefFS::Parallelizer.parallelize(inputs, options, &block)
      end
    end
  end
end
