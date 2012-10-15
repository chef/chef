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

require 'chef/chef_fs/file_system/base_fs_object'
require 'chef/chef_fs/file_system/nonexistent_fs_object'

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

        # Override child(name) to provide a child object by name without the network read
        def child(name)
          children.select { |child| child.name == name }.first || NonexistentFSObject.new(name, self)
        end

        def can_have_child?(name, is_dir)
          true
        end

        # Abstract: children
      end
    end
  end
end
