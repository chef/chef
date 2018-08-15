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
        class ChefRepositoryFileSystemCookbookArtifactDir < ChefRepositoryFileSystemCookbookDir
          # Override from parent
          def cookbook_version
            loader = Chef::Cookbook::CookbookVersionLoader.new(file_path, parent.chefignore)
            cookbook_name, _dash, identifier = name.rpartition("-")
            # KLUDGE: We shouldn't have to use instance_variable_set
            loader.instance_variable_set(:@cookbook_name, cookbook_name)
            loader.load_cookbooks
            cookbook_version = loader.cookbook_version
            cookbook_version.identifier = identifier
            cookbook_version
          end
        end
      end
    end
  end
end
