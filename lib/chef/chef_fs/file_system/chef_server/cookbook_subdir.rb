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

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        class CookbookSubdir < BaseFSDir
          def initialize(name, parent, ruby_only, recursive)
            super(name, parent)
            @children = []
            @ruby_only = ruby_only
            @recursive = recursive
          end

          attr_reader :versions
          attr_reader :children

          def add_child(child)
            @children << child
          end

          def can_have_child?(name, is_dir)
            if is_dir
              return false if !@recursive
            else
              return false if @ruby_only && name !~ /\.rb$/
            end
            true
          end

          def make_child_entry(name)
            result = @children.find { |child| child.name == name } if @children
            result || NonexistentFSObject.new(name, self)
          end

          def rest
            parent.rest
          end
        end
      end
    end
  end
end
