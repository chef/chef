#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
require "chef/chef_fs/file_system/chef_server/rest_list_dir"
require "chef/chef_fs/file_system/chef_server/role_entry"
require "chef/chef_fs/file_system/not_found_error"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class RolesDir < RestListDir
          def can_have_child?(name, is_dir)
            %w{ .rb .json }.include?(File.extname(name)) && !is_dir
          end

          def child_name(name)
            if File.extname(name) == ".rb"
              name.gsub(/.rb$/, ".json")
            else
              name
            end
          end

          def make_child_entry(name, exists = nil)
            cn = child_name(name)
            @children.select { |child| child.name == cn }.first if @children
            RoleEntry.new(cn, self, exists)
          end

        end
      end
    end
  end
end
