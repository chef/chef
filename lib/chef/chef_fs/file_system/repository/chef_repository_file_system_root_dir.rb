#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

require "chef/chef_fs/file_system/base_fs_dir"
require "chef/chef_fs/file_system/repository/acls_dir"
require "chef/chef_fs/file_system/repository/clients_dir"
require "chef/chef_fs/file_system/repository/cookbooks_dir"
require "chef/chef_fs/file_system/repository/cookbook_artifacts_dir"
require "chef/chef_fs/file_system/repository/containers_dir"
require "chef/chef_fs/file_system/repository/data_bags_dir"
require "chef/chef_fs/file_system/repository/environments_dir"
require "chef/chef_fs/file_system/repository/groups_dir"
require "chef/chef_fs/file_system/repository/nodes_dir"
require "chef/chef_fs/file_system/repository/policy_groups_dir"
require "chef/chef_fs/file_system/repository/roles_dir"
require "chef/chef_fs/file_system/repository/users_dir"
require "chef/chef_fs/file_system/repository/client_keys_dir"
require "chef/chef_fs/file_system/repository/file_system_entry"
require "chef/chef_fs/file_system/repository/policies_dir"
require "chef/chef_fs/file_system/repository/versioned_cookbooks_dir"
require "chef/chef_fs/file_system/multiplexed_dir"
require "chef/chef_fs/data_handler/client_data_handler"
require "chef/chef_fs/data_handler/client_key_data_handler"
require "chef/chef_fs/data_handler/environment_data_handler"
require "chef/chef_fs/data_handler/node_data_handler"
require "chef/chef_fs/data_handler/policy_data_handler"
require "chef/chef_fs/data_handler/policy_group_data_handler"
require "chef/chef_fs/data_handler/role_data_handler"
require "chef/chef_fs/data_handler/user_data_handler"
require "chef/chef_fs/data_handler/group_data_handler"
require "chef/chef_fs/data_handler/container_data_handler"
require "chef/win32/security" if Chef::Platform.windows?

class Chef
  module ChefFS
    module FileSystem
      module Repository

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
          def initialize(child_paths, root_paths = [], chef_config = Chef::Config)
            super("", nil)
            @child_paths = child_paths
            @root_paths = root_paths
            @versioned_cookbooks = chef_config[:versioned_cookbooks]
          end

          attr_accessor :write_pretty_json

          attr_reader :root_paths
          attr_reader :child_paths
          attr_reader :versioned_cookbooks

          CHILDREN = %w{org.json invitations.json members.json}

          def children
            @children ||= begin
                            result = child_paths.keys.sort.map { |name| make_child_entry(name) }
                            result += CHILDREN.map { |name| make_child_entry(name) }
                            result.select { |c| c && c.exists? }.sort_by { |c| c.name }
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
                  Dir.mkdir(path, 0700)
                  if Chef::Platform.windows?
                    all_mask = Chef::ReservedNames::Win32::API::Security::GENERIC_ALL
                    administrators = Chef::ReservedNames::Win32::Security::SID.Administrators
                    owner = Chef::ReservedNames::Win32::Security::SID.default_security_object_owner
                    dacl = Chef::ReservedNames::Win32::Security::ACL.create([
                      Chef::ReservedNames::Win32::Security::ACE.access_allowed(owner, all_mask),
                      Chef::ReservedNames::Win32::Security::ACE.access_allowed(administrators, all_mask),
                    ])
                    so = Chef::ReservedNames::Win32::Security::SecurableObject.new(path)
                    so.owner = owner
                    so.set_dacl(dacl, false)
                  end
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
            repo_paths = root_paths || [ File.dirname(child_paths["cookbooks"][0]) ]
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
                dir = FileSystemEntry.new(name, parent, path)
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
            if CHILDREN.include?(name)
              return nil if !root_dir
              return root_dir.child(name)
            end

            paths = (child_paths[name] || []).select { |path| File.exists?(path) }
            if paths.size == 0
              return NonexistentFSObject.new(name, self)
            end
            case name
            when "acls"
              dirs = paths.map { |path| AclsDir.new(name, self, path) }
            when "client_keys"
              dirs = paths.map { |path| ClientKeysDir.new(name, self, path) }
            when "clients"
              dirs = paths.map { |path| ClientsDir.new(name, self, path) }
            when "containers"
              dirs = paths.map { |path| ContainersDir.new(name, self, path) }
            when "cookbooks"
              if versioned_cookbooks
                dirs = paths.map { |path| VersionedCookbooksDir.new(name, self, path) }
              else
                dirs = paths.map { |path| CookbooksDir.new(name, self, path) }
              end
            when "cookbook_artifacts"
              dirs = paths.map { |path| CookbookArtifactsDir.new(name, self, path) }
            when "data_bags"
              dirs = paths.map { |path| DataBagsDir.new(name, self, path) }
            when "environments"
              dirs = paths.map { |path| EnvironmentsDir.new(name, self, path) }
            when "groups"
              dirs = paths.map { |path| GroupsDir.new(name, self, path) }
            when "nodes"
              dirs = paths.map { |path| NodesDir.new(name, self, path) }
            when "policy_groups"
              dirs = paths.map { |path| PolicyGroupsDir.new(name, self, path) }
            when "policies"
              dirs = paths.map { |path| PoliciesDir.new(name, self, path) }
            when "roles"
              dirs = paths.map { |path| RolesDir.new(name, self, path) }
            when "users"
              dirs = paths.map { |path| UsersDir.new(name, self, path) }
            else
              raise "Unknown top level path #{name}"
            end
            MultiplexedDir.new(dirs)
          end
        end
      end
    end
  end
end
