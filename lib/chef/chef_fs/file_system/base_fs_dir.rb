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

require "chef/chef_fs/file_system/base_fs_object"
require "chef/chef_fs/file_system/nonexistent_fs_object"

class Chef
  module ChefFS
    module FileSystem
      class BaseFSDir < BaseFSObject
        def initialize(name, parent)
          super
        end

        def dir?
          true
        end

        def can_have_child?(name, is_dir)
          true
        end

        # An empty children array is an empty dir
        def empty?
          children.empty?
        end

        # Abstract: children
      end
    end
  end
end
