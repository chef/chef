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

require 'chef/chef_fs/path_utils'

class Chef
  module ChefFS
    module FileSystem
      class BaseFSObject
        def initialize(name, parent)
          @parent = parent
          @name = name
          if parent
            @path = Chef::ChefFS::PathUtils::join(parent.path, name)
          else
            if name != ''
              raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
            end
            @path = '/'
          end
        end

        attr_reader :name
        attr_reader :parent
        attr_reader :path

        def root
          parent ? parent.root : self
        end

        def path_for_printing
          if parent
            parent_path = parent.path_for_printing
            if parent_path == '.'
              name
            else
              Chef::ChefFS::PathUtils::join(parent.path_for_printing, name)
            end
          else
            name
          end
        end

        def dir?
          false
        end

        def exists?
          true
        end

        def child(name)
          NonexistentFSObject.new(name, self)
        end

        # Override can_have_child? to report whether a given file *could* be added
        # to this directory.  (Some directories can't have subdirs, some can only have .json
        # files, etc.)
        def can_have_child?(name, is_dir)
          false
        end

        # Override this if you have a special comparison algorithm that can tell
        # you whether this entry is the same as another--either a quicker or a
        # more reliable one.  Callers will use this to decide whether to upload,
        # download or diff an object.
        #
        # You should not override this if you're going to do the standard
        # +self.read == other.read+.  If you return +nil+, the caller will call
        # +other.compare_to(you)+ instead.  Give them a chance :)
        #
        # ==== Parameters
        #
        # * +other+ - the entry to compare to
        #
        # ==== Returns
        #
        # * +[ are_same, value, other_value ]+
        #   +are_same+ may be +true+, +false+ or +nil+ (which means "don't know").
        #   +value+ and +other_value+ must either be the text of +self+ or +other+,
        #   +:none+ (if the entry does not exist or has no value) or +nil+ if the
        #   value was not retrieved.
        # * +nil+ if a definitive answer cannot be had and nothing was retrieved.
        #
        # ==== Example
        #
        #     are_same, value, other_value = entry.compare_to(other)
        #     if are_same.nil?
        #       are_same, other_value, value = other.compare_to(entry)
        #     end
        #     if are_same.nil?
        #       value = entry.read if value.nil?
        #       other_value = entry.read if other_value.nil?
        #       are_same = (value == other_value)
        #     end
        def compare_to(other)
          return nil
        end

        # Important directory attributes: name, parent, path, root
        # Overridable attributes: dir?, child(name), path_for_printing
        # Abstract: read, write, delete, children
      end
    end
  end
end
