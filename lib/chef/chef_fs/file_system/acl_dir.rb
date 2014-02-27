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
require 'chef/chef_fs/file_system/acl_entry'
require 'chef/chef_fs/file_system/operation_not_allowed_error'

class Chef
  module ChefFS
    module FileSystem
      class AclDir < BaseFSDir
        def api_path
          parent.parent.child(name).api_path
        end

        def child(name)
          result = @children.select { |child| child.name == name }.first if @children
          result ||= can_have_child?(name, false) ?
                     AclEntry.new(name, self) : NonexistentFSObject.new(name, self)
        end

        def can_have_child?(name, is_dir)
          name =~ /\.json$/ && !is_dir
        end

        def children
          if @children.nil?
            # Grab the ACTUAL children (/nodes, /containers, etc.) and get their names
            names = parent.parent.child(name).children.map { |child| child.dir? ? "#{child.name}.json" : child.name }
            @children = names.map { |name| AclEntry.new(name, self, true) }
          end
          @children
        end

        def create_child(name, file_contents)
          raise OperationNotAllowedError.new(:create_child, self), "ACLs can only be updated, and can only be created when the corresponding object is created."
        end

        def data_handler
          parent.data_handler
        end

        def rest
          parent.rest
        end
      end
    end
  end
end
