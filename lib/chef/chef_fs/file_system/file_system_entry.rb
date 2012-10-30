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
require 'chef/chef_fs/file_system/rest_list_dir'
require 'chef/chef_fs/file_system/not_found_error'
require 'chef/chef_fs/path_utils'
require 'fileutils'

class Chef
  module ChefFS
    module FileSystem
      class FileSystemEntry < BaseFSDir
        def initialize(name, parent, file_path = nil)
          super(name, parent)
          @file_path = file_path || "#{parent.file_path}/#{name}"
        end

        attr_reader :file_path

        def path_for_printing
          Chef::ChefFS::PathUtils::relative_to(file_path, File.expand_path(Dir.pwd))
        end

        def children
          begin
            @children ||= Dir.entries(file_path).select { |entry| entry != '.' && entry != '..' }.map { |entry| FileSystemEntry.new(entry, self) }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{file_path} not found"
          end
        end

        def create_child(child_name, file_contents=nil)
          result = FileSystemEntry.new(child_name, self)
          if file_contents
            result.write(file_contents)
          else
            Dir.mkdir(result.file_path)
          end
          result
        end

        def dir?
          File.directory?(file_path)
        end

        def delete(recurse)
          if dir?
            if recurse
              FileUtils.rm_rf(file_path)
            else
              File.rmdir(file_path)
            end
          else
            File.delete(file_path)
          end
        end

        def read
          begin
            File.open(file_path, "rb") {|f| f.read}
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new($!), "#{file_path} not found"
          end
        end

        def write(content)
          File.open(file_path, 'wb') do |file|
            file.write(content)
          end
        end
      end
    end
  end
end
