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

require "chef/chef_fs/file_system/chef_server/cookbook_dir"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class VersionedCookbookDir < CookbookDir
          # See Erchef code
          # https://github.com/chef/chef_objects/blob/968a63344d38fd507f6ace05f73d53e9cd7fb043/src/chef_regex.erl#L94
          VALID_VERSIONED_COOKBOOK_NAME = /^([.a-zA-Z0-9_-]+)-(\d+\.\d+\.\d+)$/

          def initialize(name, parent, options = {})
            super(name, parent)
            # If the name is apache2-1.0.0 and versioned_cookbooks is on, we know
            # the actual cookbook_name and version.
            if name =~ VALID_VERSIONED_COOKBOOK_NAME
              @cookbook_name = $1
              @version = $2
            else
              @exists = false
            end
          end
        end
      end
    end
  end
end
