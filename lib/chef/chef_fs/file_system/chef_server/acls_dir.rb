#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../base_fs_dir"
require_relative "acl_dir"
require_relative "cookbooks_acl_dir"
require_relative "policies_acl_dir"
require_relative "acl_entry"
require_relative "../../data_handler/acl_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class AclsDir < BaseFSDir
          ENTITY_TYPES = %w{clients containers cookbook_artifacts cookbooks data_bags environments groups nodes policies policy_groups roles}.freeze # we don't read sandboxes, so we don't read their acls

          def data_handler
            @data_handler ||= Chef::ChefFS::DataHandler::AclDataHandler.new
          end

          def api_path
            parent.api_path
          end

          def make_child_entry(name)
            children.find { |child| child.name == name }
          end

          def can_have_child?(name, is_dir)
            is_dir ? ENTITY_TYPES.include?(name) : name == "organization.json"
          end

          def children
            if @children.nil?
              @children = ENTITY_TYPES.map do |entity_type|
                # All three of these can be versioned (NAME-VERSION), but only have
                # one ACL that covers them all (NAME.json).
                case entity_type
                when "cookbooks", "cookbook_artifacts"
                  CookbooksAclDir.new(entity_type, self)
                when "policies"
                  PoliciesAclDir.new(entity_type, self)
                else
                  AclDir.new(entity_type, self)
                end
              end
              @children << AclEntry.new("organization.json", self, true) # the org acl is retrieved as GET /organizations/ORGNAME/ANYTHING/_acl
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
end
