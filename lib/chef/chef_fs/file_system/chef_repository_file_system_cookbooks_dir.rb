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

require 'chef/chef_fs/file_system/chef_repository_file_system_entry'
require 'chef/chef_fs/file_system/chef_repository_file_system_cookbook_dir'
require 'chef/cookbook/chefignore'

class Chef
  module ChefFS
    module FileSystem
      class ChefRepositoryFileSystemCookbooksDir < ChefRepositoryFileSystemEntry
        def initialize(name, parent, file_path)
          super(name, parent, file_path)
          begin
            @chefignore = Chef::Cookbook::Chefignore.new(self.file_path)
          rescue Errno::EISDIR
          rescue Errno::EACCES
            # Work around a bug in Chefignore when chefignore is a directory
          end
        end

        attr_reader :chefignore

        def children
          begin
            Dir.entries(file_path).sort.
                select { |child_name| can_have_child?(child_name, File.directory?(File.join(file_path, child_name))) }.
                map { |child_name| make_child(child_name) }.
                select do |entry|
                  # empty cookbooks and cookbook directories are ignored
                  if entry.children.size == 0
                    Chef::Log.warn("Cookbook '#{entry.name}' is empty or entirely chefignored at #{entry.path_for_printing}")
                    false
                  else
                    true
                  end
                end
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end
        end

        def can_have_child?(name, is_dir)
          is_dir && !name.start_with?('.')
        end

        protected

        def make_child(child_name)
          ChefRepositoryFileSystemCookbookDir.new(child_name, self)
        end
      end
    end
  end
end
