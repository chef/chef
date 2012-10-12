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

      def base_path
        @base_path ||= begin
          relative_to_base = Chef::ChefFS::PathUtils::relative_to(File.expand_path(Dir.pwd), chef_repo)
          relative_to_base == '.' ? '/' : "/#{relative_to_base}"
        end
      end

      def chef_fs
        @chef_fs ||= Chef::ChefFS::FileSystem::ChefServerRootDir.new("remote", Chef::Config, config[:repo_mode])
      end

      def chef_repo
        @chef_repo ||= File.expand_path(File.join(Chef::Config.cookbook_path, ".."))
      end

      def format_path(path)
        if path[0,base_path.length] == base_path
          if path == base_path
            return "."
          elsif path[base_path.length] == "/"
            return path[base_path.length + 1, path.length - base_path.length - 1]
          elsif base_path == "/" && path[0] == "/"
            return path[1, path.length - 1]
          end
        end
        path
      end

      def local_fs
        @local_fs ||= Chef::ChefFS::FileSystem::ChefRepositoryFileSystemRootDir.new(chef_repo)
      end

      def pattern_args
        @pattern_args ||= pattern_args_from(name_args)
      end

      def pattern_args_from(args)
        args.map { |arg| Chef::ChefFS::FilePattern::relative_to(base_path, arg) }.to_a
      end

    end
  end
end
