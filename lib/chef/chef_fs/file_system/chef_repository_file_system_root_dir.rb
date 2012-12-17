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
require 'chef/chef_fs/file_system/chef_repository_file_system_entry'
require 'chef/chef_fs/file_system/multiplexed_dir'

class Chef
  module ChefFS
    module FileSystem
      class ChefRepositoryFileSystemRootDir < BaseFSDir
        def initialize(child_paths)
          super("", nil)
          @child_paths = child_paths
        end

        attr_reader :child_paths

        def children
          @children ||= child_paths.keys.map { |name| make_child_entry(name) }.select { |child| !child.nil? }
        end

        def can_have_child?(name, is_dir)
          child_paths.has_key?(name) && is_dir
        end

        def create_child(name, file_contents = nil)
          child_paths[name].each do |path|
            Dir.mkdir(path)
          end
          make_child_entry(name)
        end

        def ignore_empty_directories?
          false
        end

        def chefignore
          nil
        end

        private

        def make_child_entry(name)
          paths = child_paths[name].select do |path|
            File.exists?(path)
          end
          if paths.size == 0
            return nil
          end
          dirs = paths.map { |path| ChefRepositoryFileSystemEntry.new(name, self, path) }
          MultiplexedDir.new(dirs)
        end
      end
    end
  end
end
