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

require "chef/chef_fs/file_system/repository/chef_repository_file_system_cookbook_dir"

class Chef
  module ChefFS
    module FileSystem
      module Repository
        class ChefRepositoryFileSystemVersionedCookbookDir < ChefRepositoryFileSystemCookbookDir
          # Override from parent
          def cookbook_version
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            # We need the canonical cookbook name if we are using versioned cookbooks, but we don't
            # want to spend a lot of time adding code to the main Chef libraries
            canonical_name = canonical_cookbook_name(File.basename(file_path))
            raise "When versioned_cookbooks mode is on, cookbook #{file_path} must match format <cookbook_name>-x.y.z" unless canonical_name
            # KLUDGE: We shouldn't have to use instance_variable_set
            loader.instance_variable_set(:@cookbook_name, canonical_name)
            loader.load_cookbooks
            loader.cookbook_version
          end
        end
      end
    end
  end
end
