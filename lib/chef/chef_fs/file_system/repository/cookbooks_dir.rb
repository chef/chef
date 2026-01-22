#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "directory"
require_relative "chef_repository_file_system_cookbook_dir"
require_relative "../../../cookbook/chefignore"

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class CookbooksDir < Repository::Directory

          def chefignore
            @chefignore ||= Chef::Cookbook::Chefignore.new(file_path)
          rescue Errno::EISDIR, Errno::EACCES
            # Work around a bug in Chefignore when chefignore is a directory
          end

          def write_cookbook(cookbook_path, cookbook_version_json, from_fs)
            cookbook_name = File.basename(cookbook_path)
            make_child_entry(cookbook_name).write(cookbook_path, cookbook_version_json, from_fs)
          end

          protected

          def make_child_entry(child_name)
            ChefRepositoryFileSystemCookbookDir.new(child_name, self)
          end

        end
      end
    end
  end
end
