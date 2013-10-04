#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/chef_fs/file_system/chef_repository_file_system_entry'
require 'chef/chef_fs/file_system/acls_dir'
require 'chef/chef_fs/data_handler/acl_data_handler'

class Chef
  module ChefFS
    module FileSystem
      class ChefRepositoryFileSystemAclsDir < ChefRepositoryFileSystemEntry
        def initialize(name, parent, path = nil)
          super(name, parent, path, Chef::ChefFS::DataHandler::AclDataHandler.new)
        end

        def can_have_child?(name, is_dir)
          is_dir ? Chef::ChefFS::FileSystem::AclsDir::ENTITY_TYPES.include?(name) : name == 'organization.json'
        end
      end
    end
  end
end