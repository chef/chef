#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

class Chef
  module ChefFS
    module FileSystem
      module Repository

        class BaseFile

          attr_reader :name
          attr_reader :parent
          attr_reader :path
          attr_reader :file_path
          attr_reader :data_handler

          def initialize(name, parent)
            @parent = parent
            @name = name
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
            @file_path = "#{parent.file_path}/#{name}"
          end

          def dir?
            false
          end

          def is_json_file?
            File.extname(name) == ".json"
          end

          def name_valid?
            !name.start_with?(".") && is_json_file?
          end

          def fs_entry_valid?
            name_valid? && exists?
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

          attr_writer :write_pretty_json
          def write_pretty_json
            @write_pretty_json.nil? ? root.write_pretty_json : @write_pretty_json
          end

          def path_for_printing
            file_path
          end

          def delete(_)
            File.delete(file_path)
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def exists?
            File.file?(file_path)
          end

          def minimize(content, entry)
            object = Chef::JSONCompat.parse(content)
            object = data_handler.normalize(object, entry)
            object = data_handler.minimize(object, entry)
            Chef::JSONCompat.to_json_pretty(object)
          end

          def read
            File.open(file_path, "rb") { |f| f.read }
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def write(content)
            if content && write_pretty_json && is_json_file?
              content = minimize(content, self)
            end
            File.open(file_path, "wb") do |file|
              file.write(content)
            end
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
