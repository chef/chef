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
require 'chef/chef_fs/file_system/rest_list_entry'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/file_system/operation_skipped_error'

class Chef
  module ChefFS
    module FileSystem
      class EnvironmentsDir < RestListDir
        def initialize(parent)
          super("environments", parent)
        end

        def _make_child_entry(name, exists = nil)
          if name == '_default.json'
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
            Chef::Log.warn("The default environment (#{name}) cannot be deleted.  Skipping.")
            raise NotFoundError, "Nonexistent #{path_for_printing}" if !exists?
            raise OperationSkippedError.new(:delete), "#{path_for_printing} cannot be deleted."
          end

          def write(file_contents)
            Chef::Log.warn("The default environment (#{name}) cannot be deleted.  Skipping.")
            raise NotFoundError, "Nonexistent #{path_for_printing}" if !exists?
            raise OperationSkippedError.new(:write), "#{path_for_printing} cannot be updated."
          end
        end
      end
    end
  end
end
