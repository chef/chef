#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright 2016, Chef Software Inc.
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

require "chef/chef_fs/data_handler/role_data_handler"
class Chef
  module ChefFS
    module FileSystem
      module Repository
        class RubyOrJsonFile < ChefRepositoryFileSystemEntry
          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :file_path
          attr_reader :data_handler

          def initialize(name, parent)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
            @data_handler = parent.data_handler
            @file_path = "#{parent.file_path}/#{name}"
          end

          def name_valid?
            !name.start_with?(".") && %w{ .rb .json }.include?(File.extname(name))
          end

          def fs_entry_valid?
            name_valid? && File.file?(file_path)
          end

          def create(file_contents)
            if exists?
              raise Chef::ChefFS::FileSystem::AlreadyExistsError.new(:create_child, self)
            else
              write(file_contents)
            end
          end

          def can_have_child?(name, is_dir)
            false
          end

          def path_for_printing
            file_path
          end

          def read
            if File.extname(file_path) == ".rb"
              data_handler.from_ruby(file_path).to_json
            else
              File.read(file_path)
            end
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def root
            parent.root
          end

          def compare_to(other)
            nil
          end
        end
      end
    end
  end
end
