#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "chef/chef_fs/file_system/chef_server/acl_dir"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class CookbooksAclDir < AclDir
          # If versioned_cookbooks is on, the list of cookbooks will have versions
          # in them.  But all versions of a cookbook have the same acl, so even if
          # we have cookbooks/apache2-1.0.0 and cookbooks/apache2-1.1.2, we will
          # only have one acl: acls/cookbooks/apache2.json.  Thus, the list of
          # children of acls/cookbooks is a unique list of cookbook *names*.
          def children
            if @children.nil?
              names = parent.parent.child(name).children.map { |child| "#{child.cookbook_name}.json" }
              @children = names.uniq.map { |name| make_child_entry(name, true) }
            end
            @children
          end
        end
      end
    end
  end
end
