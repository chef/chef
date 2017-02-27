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
require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class EnvironmentsDir < RestListDir
          def make_child_entry(name, exists = nil)
            if File.basename(name, ".*") == "_default"
              DefaultEnvironmentEntry.new(name, self, exists)
            else
              super
            end
          end

          class DefaultEnvironmentEntry < RestListEntry
            def initialize(name, parent, exists = nil)
              super(name, parent)
              @exists = exists
            end

            def delete(recurse)
              raise NotFoundError.new(self) if !exists?
              raise DefaultEnvironmentCannotBeModifiedError.new(:delete, self)
            end

            def write(file_contents)
              raise NotFoundError.new(self) if !exists?
              raise DefaultEnvironmentCannotBeModifiedError.new(:write, self)
            end
          end
        end
      end
    end
  end
end
