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

require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/acl_dir'
require 'chef/chef_fs/file_system/cookbooks_acl_dir'
require 'chef/chef_fs/file_system/acl_entry'
require 'chef/chef_fs/data_handler/acl_data_handler'

class Chef
  module ChefFS
    module FileSystem
      class AclsDir < BaseFSDir
        ENTITY_TYPES = %w(clients containers cookbooks data_bags environments groups nodes roles) # we don't read sandboxes, so we don't read their acls

        def initialize(parent)
          super('acls', parent)
        end

        def data_handler
          @data_handler ||= Chef::ChefFS::DataHandler::AclDataHandler.new
        end

        def api_path
          parent.api_path
        end

        def can_have_child?(name, is_dir)
          is_dir ? ENTITY_TYPES.include(name) : name == 'organization.json'
        end

        def children
          if @children.nil?
            @children = ENTITY_TYPES.map do |entity_type|
              case entity_type
              when 'cookbooks'
                CookbooksAclDir.new(entity_type, self)
              else
                AclDir.new(entity_type, self)
              end
            end
            @children << AclEntry.new('organization.json', self, true) # the org acl is retrieved as GET /organizations/ORGNAME/ANYTHINGATALL/_acl
          end
          @children
        end

        def rest
          parent.rest
        end
      end
    end
  end
end
