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

require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_entry'
require 'chef/chef_fs/file_system/chef_repository_file_system_acls_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_cookbooks_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_data_bags_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_policies_dir'
require 'chef/chef_fs/file_system/multiplexed_dir'
require 'chef/chef_fs/data_handler/client_data_handler'
require 'chef/chef_fs/data_handler/environment_data_handler'
require 'chef/chef_fs/data_handler/node_data_handler'
require 'chef/chef_fs/data_handler/role_data_handler'
require 'chef/chef_fs/data_handler/user_data_handler'
require 'chef/chef_fs/data_handler/group_data_handler'
require 'chef/chef_fs/data_handler/container_data_handler'

class Chef
  module ChefFS
    module FileSystem

      #
      # Represents the root of a local Chef repository, with directories for
      # nodes, cookbooks, roles, etc. under it.
      #
      class ChefRepositoryFileSystemRootDir < BaseFSDir
        #
        # Create a new Chef Repository File System root.
        #
        # == Parameters
        # [child_paths]
        #   A hash of child paths, e.g.:
        #     "nodes" => [ '/var/nodes', '/home/jkeiser/nodes' ],
        #     "roles" => [ '/var/roles' ],
        #     ...
        # [root_paths]
        #   An array of paths representing the top level, where
        #   +org.json+, +members.json+, and +invites.json+ will be stored.
        # [chef_config] - a hash of options that looks suspiciously like the ones
        #   stored in Chef::Config, containing at least these keys:
        #   :versioned_cookbooks:: whether to include versions in cookbook names
        def initialize(child_paths, root_paths=[], chef_config=Chef::Config)
          super("", nil)
          @child_paths = child_paths
          @root_paths = root_paths
          @versioned_cookbooks = chef_config[:versioned_cookbooks]
        end

        attr_accessor :write_pretty_json

        attr_reader :root_paths
        attr_reader :child_paths
        attr_reader :versioned_cookbooks

        CHILDREN = %w(invitations.json members.json org.json)

        def children
          @children ||= begin
            result = child_paths.keys.sort.map { |name| make_child_entry(name) }.select { |child| !child.nil? }
            result += root_dir.children.select { |c| CHILDREN.include?(c.name) } if root_dir
            result.sort_by { |c| c.name }
          end
        end

        def can_have_child?(name, is_dir)
          if is_dir
            child_paths.has_key?(name)
          elsif root_dir
            CHILDREN.include?(name)
          else
            false
          end
        end

        def create_child(name, file_contents = nil)
          if file_contents
            child = root_dir.create_child(name, file_contents)
          else
            child_paths[name].each do |path|
              begin
                Dir.mkdir(path)
              rescue Errno::EEXIST
              end
            end
            child = make_child_entry(name)
          end
          @children = nil
          child
        end

        def json_class
          nil
        end

        # Used to print out a human-readable file system description
        def fs_description
          repo_paths = root_paths || [ File.dirname(child_paths['cookbooks'][0]) ]
          result = "repository at #{repo_paths.join(', ')}\n"
          if versioned_cookbooks
            result << "  Multiple versions per cookbook\n"
          else
            result << "  One version per cookbook\n"
          end
          child_paths.each_pair do |name, paths|
            if paths.any? { |path| !repo_paths.include?(File.dirname(path)) }
              result << "  #{name} at #{paths.join(', ')}\n"
            end
          end
          result
        end

        private

        #
        # A FileSystemEntry representing the root path where invites.json,
        # members.json and org.json may be found.
        #
        def root_dir
          existing_paths = root_paths.select { |path| File.exists?(path) }
          if existing_paths.size > 0
            MultiplexedDir.new(existing_paths.map do |path|
              dir = ChefRepositoryFileSystemEntry.new(name, parent, path)
              dir.write_pretty_json = !!write_pretty_json
              dir
            end)
          end
        end

        #
        # Create a child entry of the appropriate type:
        # cookbooks, data_bags, acls, etc.  All will be multiplexed (i.e. if
        # you have multiple paths for cookbooks, the multiplexed dir will grab
        # cookbooks from all of them when you list or grab them).
        #
        def make_child_entry(name)
          paths = child_paths[name].select do |path|
            File.exists?(path)
          end
          if paths.size == 0
            return nil
          end
          if name == 'cookbooks'
            dirs = paths.map { |path| ChefRepositoryFileSystemCookbooksDir.new(name, self, path) }
          elsif name == 'data_bags'
            dirs = paths.map { |path| ChefRepositoryFileSystemDataBagsDir.new(name, self, path) }
          elsif name == 'policies'
            dirs = paths.map { |path| ChefRepositoryFileSystemPoliciesDir.new(name, self, path) }
          elsif name == 'acls'
            dirs = paths.map { |path| ChefRepositoryFileSystemAclsDir.new(name, self, path) }
          else
            data_handler = case name
              when 'clients'
                Chef::ChefFS::DataHandler::ClientDataHandler.new
              when 'environments'
                Chef::ChefFS::DataHandler::EnvironmentDataHandler.new
              when 'nodes'
                Chef::ChefFS::DataHandler::NodeDataHandler.new
              when 'roles'
                Chef::ChefFS::DataHandler::RoleDataHandler.new
              when 'users'
                Chef::ChefFS::DataHandler::UserDataHandler.new
              when 'groups'
                Chef::ChefFS::DataHandler::GroupDataHandler.new
              when 'containers'
                Chef::ChefFS::DataHandler::ContainerDataHandler.new
              else
                raise "Unknown top level path #{name}"
              end
            dirs = paths.map { |path| ChefRepositoryFileSystemEntry.new(name, self, path, data_handler) }
          end
          MultiplexedDir.new(dirs)
        end
      end
    end
  end
end
