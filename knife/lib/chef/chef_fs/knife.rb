#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require_relative "../knife"
require "pathname" unless defined?(Pathname)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)
require "chef-utils/parallel_map" unless defined?(ChefUtils::ParallelMap)

using ChefUtils::ParallelMap

class Chef
  module ChefFS
    class Knife < Chef::Knife
      # Workaround for CHEF-3932
      def self.deps
        super do
          require "chef/config" unless defined?(Chef::Config)
          require "chef/chef_fs/config" unless defined?(Chef::ChefFS::Config)
          require "chef/chef_fs/file_pattern" unless defined?(Chef::ChefFS::FilePattern)
          require "chef/chef_fs/path_utils" unless defined?(Chef::ChefFS::PathUtils)
          yield
        end
      end

      def self.inherited(c)
        super

        # Ensure we always get to do our includes, whether subclass calls deps or not
        c.deps do
        end
      end

      option :repo_mode,
        long: "--repo-mode MODE",
        description: "Specifies the local repository layout.  Values: static, everything, hosted_everything.  Default: everything/hosted_everything"

      option :chef_repo_path,
        long: "--chef-repo-path PATH",
        description: "Overrides the location of #{ChefUtils::Dist::Infra::PRODUCT} repo. Default is specified by chef_repo_path in the config"

      option :concurrency,
        long: "--concurrency THREADS",
        description: "Maximum number of simultaneous requests to send (default: 10)"

      def configure_chef
        super
        Chef::Config[:repo_mode] = config[:repo_mode] if config[:repo_mode]
        Chef::Config[:concurrency] = config[:concurrency].to_i if config[:concurrency]

        # --chef-repo-path forcibly overrides all other paths
        if config[:chef_repo_path]
          Chef::Config[:chef_repo_path] = config[:chef_repo_path]
          Chef::ChefFS::Config::INFLECTIONS.each_value do |variable_name|
            Chef::Config.delete("#{variable_name}_path".to_sym)
          end
        end

        @chef_fs_config = Chef::ChefFS::Config.new(Chef::Config, Dir.pwd, config, ui)

        ChefUtils::DefaultThreadPool.instance.threads = (Chef::Config[:concurrency] || 10) - 1
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
        args.map { |arg| pattern_arg_from(arg) }
      end

      def pattern_arg_from(arg)
        inferred_path = nil
        if Chef::ChefFS::PathUtils.is_absolute?(arg)
          # We should be able to use this as-is - but the user might have incorrectly provided
          # us with a path that is based off of the OS root path instead of the Chef-FS root.
          # Do a quick and dirty sanity check.
          if possible_server_path = @chef_fs_config.server_path(arg)
            ui.warn("The absolute path provided is suspicious: #{arg}")
            ui.warn("If you wish to refer to a file location, please provide a path that is rooted at the chef-repo.")
            ui.warn("Consider writing '#{possible_server_path}' instead of '#{arg}'")
          end
          # Use the original path because we can't be sure.
          inferred_path = arg
        elsif arg[0, 1] == "~"
          # Let's be nice and fix it if possible - but warn the user.
          ui.warn("A path relative to a user home directory has been provided: #{arg}")
          ui.warn("Paths provided need to be rooted at the chef-repo being considered or be relative paths.")
          inferred_path = @chef_fs_config.server_path(arg)
          ui.warn("Using '#{inferred_path}' as the path instead of '#{arg}'.")
        elsif Pathname.new(arg).absolute?
          # It is definitely a system absolute path (such as C:\ or \\foo\bar) but it cannot be
          # interpreted as a Chef-FS absolute path.  Again attempt to be nice but warn the user.
          ui.warn("An absolute file system path that isn't a server path was provided: #{arg}")
          ui.warn("Paths provided need to be rooted at the chef-repo being considered or be relative paths.")
          inferred_path = @chef_fs_config.server_path(arg)
          ui.warn("Using '#{inferred_path}' as the path instead of '#{arg}'.")
        elsif @chef_fs_config.base_path.nil?
          # These are all relative paths.  We can't resolve and root paths unless we are in the
          # chef repo.
          ui.error("Attempt to use relative path '#{arg}' when current directory is outside the repository path.")
          ui.error("Current working directory is '#{@chef_fs_config.cwd}'.")
          exit(1)
        else
          inferred_path = Chef::ChefFS::PathUtils.join(@chef_fs_config.base_path, arg)
        end
        Chef::ChefFS::FilePattern.new(inferred_path)
      end

      def format_path(entry)
        @chef_fs_config.format_path(entry)
      end

      def parallelize(inputs, options = {}, &block)
        inputs.parallel_map(&block)
      end

      def discover_repo_dir(dir)
        %w{.chef cookbooks data_bags environments roles}.each do |subdir|
          return dir if File.directory?(File.join(dir, subdir))
        end
        # If this isn't it, check the parent
        parent = File.dirname(dir)
        if parent && parent != dir
          discover_repo_dir(parent)
        else
          nil
        end
      end
    end
  end
end
