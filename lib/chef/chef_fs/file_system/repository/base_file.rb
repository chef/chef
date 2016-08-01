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

require "chef/chef_fs/file_system_cache"

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

          alias_method :display_path, :path
          alias_method :display_name, :name

          def initialize(name, parent)
            @parent = parent

            if %w{ .rb .json }.include? File.extname(name)
              name = File.basename(name, ".*")
            end

            file_path = "#{parent.file_path}/#{name}"

            Chef::Log.debug "BaseFile: Detecting file extension for #{name}"
            ext = File.exist?(file_path + ".rb") ? ".rb" : ".json"
            name += ext
            file_path += ext

            Chef::Log.debug "BaseFile: got a file path of #{file_path} for #{name}"
            @name = name
            @path = Chef::ChefFS::PathUtils.join(parent.path, name)
            @file_path = file_path
          end

          def dir?
            false
          end

          # Used to compare names on disk to the API, for diffing.
          def bare_name
            File.basename(name, ".*")
          end

          def is_json_file?
            File.extname(file_path) == ".json"
          end

          def is_ruby_file?
            File.extname(file_path) == ".rb"
          end

          def name_valid?
            !name.start_with?(".") && (is_json_file? || is_ruby_file?)
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
            FileSystemCache.instance.delete!(file_path)
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
            if is_ruby_file?
              data_handler.from_ruby(file_path).to_json
            else
              File.open(file_path, "rb") { |f| f.read }
            end
          rescue Errno::ENOENT
            raise Chef::ChefFS::FileSystem::NotFoundError.new(self, $!)
          end

          def write(content)
            if is_ruby_file?
              raise Chef::ChefFS::FileSystem::RubyFileError.new(:write, self)
            end
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
