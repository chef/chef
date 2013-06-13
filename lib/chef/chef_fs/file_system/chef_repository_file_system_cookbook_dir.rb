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

require 'chef/chef_fs/file_system/chef_repository_file_system_cookbook_entry'
require 'chef/cookbook/chefignore'
require 'chef/cookbook/cookbook_version_loader'

class Chef
  module ChefFS
    module FileSystem
      class ChefRepositoryFileSystemCookbookDir < ChefRepositoryFileSystemCookbookEntry
        def initialize(name, parent, file_path = nil)
          super(name, parent, file_path)
        end

        def chef_object
          begin
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            # We need the canonical cookbook name if we are using versioned cookbooks, but we don't
            # want to spend a lot of time adding code to the main Chef libraries
            if Chef::Config[:versioned_cookbooks]
              _canonical_name = canonical_cookbook_name(File.basename(file_path))
              fail "When versioned_cookbooks mode is on, cookbook #{file_path} must match format <cookbook_name>-x.y.z"  unless _canonical_name

              # KLUDGE: We shouldn't have to use instance_variable_set
              loader.instance_variable_set(:@cookbook_name, _canonical_name)
            end

            loader.load_cookbooks
            return loader.cookbook_version
          rescue
            Chef::Log.error("Could not read #{path_for_printing} into a Chef object: #{$!}")
          end
          nil
        end

        # Exposed as a class method so that it can be used elsewhere
        def self.canonical_cookbook_name(entry_name)
          name_match = Chef::ChefFS::FileSystem::CookbookDir::VALID_VERSIONED_COOKBOOK_NAME.match(entry_name)
          return nil if name_match.nil?
          return name_match[1]
        end

        def canonical_cookbook_name(entry_name)
          self.class.canonical_cookbook_name(entry_name)
        end
      end
    end
  end
end
