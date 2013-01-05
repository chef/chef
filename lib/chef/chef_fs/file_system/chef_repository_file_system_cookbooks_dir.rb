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
            # Work around a bug in Chefignore when chefignore is a directory
          end
        end

        attr_reader :chefignore

        def ignore_empty_directories?
          true
        end

        def ignored?(entry)
          return true if !entry.dir?
          result = super(entry)
          if result
            Chef::Log.warn("Cookbook '#{entry.name}' is empty or entirely chefignored at #{entry.path_for_printing}")
          end
          result
        end
      end
    end
  end
end
