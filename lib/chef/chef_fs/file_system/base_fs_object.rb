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

require "chef/chef_fs/path_utils"
require "chef/chef_fs/file_system/exceptions"

class Chef
  module ChefFS
    module FileSystem
      class BaseFSObject
        def initialize(name, parent)
          @parent = parent
          @name = name
          if parent
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
          else
            if name != ""
              raise ArgumentError, "Name of root object must be empty string: was '#{name}' instead"
            end
            @path = "/"
          end
        end

        attr_reader :name
        attr_reader :parent
        attr_reader :path

        alias_method :display_path, :path
        alias_method :display_name, :name
        alias_method :bare_name, :name

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
          nil
        end

        # Override can_have_child? to report whether a given file *could* be added
        # to this directory.  (Some directories can't have subdirs, some can only have .json
        # files, etc.)
        def can_have_child?(name, is_dir)
          false
        end

        # Get a child of this entry with the given name.  This MUST always
        # return a child, even if it is NonexistentFSObject.  Overriders should
        # take caution not to do expensive network requests to get the list of
        # children to fulfill this request, unless absolutely necessary here; it
        # is intended as a quick way to traverse a hierarchy.
        #
        # For example, knife show /data_bags/x/y.json will call
        # root.child('data_bags').child('x').child('y.json'), which can then
        # directly perform a network request to retrieve the y.json data bag.  No
        # network request was necessary to retrieve
        def child(name)
          if can_have_child?(name, true) || can_have_child?(name, false)
            result = make_child_entry(name)
          end
          result || NonexistentFSObject.new(name, self)
        end

        # Override children to report your *actual* list of children as an array.
        def children
          raise NotFoundError.new(self) if !exists?
          []
        end

        # Expand this entry into a chef object (Chef::Role, ::Node, etc.)
        def chef_object
          raise NotFoundError.new(self) if !exists?
          nil
        end

        # Create a child of this entry with the given name and contents.  If
        # contents is nil, create a directory.
        #
        # NOTE: create_child_from is an optional method that can also be added to
        # your entry class, and will be called without actually reading the
        # file_contents.  This is used for knife upload /cookbooks/cookbookname.
        def create_child(name, file_contents)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:create_child, self)
        end

        # Delete this item, possibly recursively.  Entries MUST NOT delete a
        # directory unless recurse is true.
        def delete(recurse)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:delete, self)
        end

        # Ask whether this entry is a directory.  If not, it is a file.
        def dir?
          false
        end

        # Ask whether this entry exists.
        def exists?
          true
        end

        # Printable path, generally used to distinguish paths in one root from
        # paths in another.
        def path_for_printing
          if parent
            parent_path = parent.path_for_printing
            if parent_path == "."
              name
            else
              Chef::ChefFS::PathUtils.join(parent.path_for_printing, name)
            end
          else
            name
          end
        end

        def root
          parent ? parent.root : self
        end

        # Read the contents of this file entry.
        def read
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:read, self)
        end

        # Write the contents of this file entry.
        def write(file_contents)
          raise NotFoundError.new(self) if !exists?
          raise OperationNotAllowedError.new(:write, self)
        end

        # Important directory attributes: name, parent, path, root
        # Overridable attributes: dir?, child(name), path_for_printing
        # Abstract: read, write, delete, children, can_have_child?, create_child, compare_to, make_child_entry
      end # class BaseFsObject
    end
  end
end

require "chef/chef_fs/file_system/nonexistent_fs_object"
