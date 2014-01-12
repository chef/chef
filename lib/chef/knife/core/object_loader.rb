#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/dialect'

class Chef
  class Knife
    module Core
      class ObjectLoader

        attr_reader :ui
        attr_reader :klass

        include Chef::Mixin::ConvertToClassName

        class ObjectType
          FILE = 1
          FOLDER = 2
        end

        def initialize(klass, ui)
          @klass = klass
          @ui = ui
        end

        def load_from(repo_location, *components)
          unless object_file = find_file(repo_location, *components)
            ui.error "Could not find or open file '#{components.last}' in current directory or in '#{repo_location}/#{components.join('/')}'"
            exit 1
          end
          object_from_file(object_file)
        end

        # When someone makes this awesome, please update the above error message.
        def find_file(repo_location, *components)
          if file_exists_and_is_readable?(File.expand_path( components.last ))
            File.expand_path( components.last )
          else
            relative_path = File.join(Dir.pwd, repo_location, *components)
            if file_exists_and_is_readable?(relative_path)
              relative_path
            else
              nil
            end
          end
        end

        # Find all objects in the given location
        # If the object type is File it will look for all *.{json,rb}
        # files, otherwise it will lookup for folders only (useful for
        # data_bags)
        #
        # @param [String] path - base look up location
        #
        # @return [Array<String>] basenames of the found objects
        #
        # @api public
        def find_all_objects(path)
          path = File.join(path, '*')
          path << '.{json,rb}'
          objects = Dir.glob(File.expand_path(path))
          objects.map { |o| File.basename(o) }
        end

        def find_all_object_dirs(path)
          path = File.join(path, '*')
          objects = Dir.glob(File.expand_path(path))
          objects.delete_if { |o| !File.directory?(o) }
          objects.map { |o| File.basename(o) }
        end

        def object_from_file(filename)
          flavor = convert_to_snake_case(@klass.name, 'Chef')
          begin
            dialect = Chef::Dialect.find_by_extension(nil, flavor, filename)
          rescue Chef::Exceptions::DialectNotFound
            ui.fatal("Could not find a dialect for #{filename}")
            exit 30
          end
          dialect.send("compile_#{flavor}", @klass, filename)
        end

        def file_exists_and_is_readable?(file)
          File.exists?(file) && File.readable?(file)
        end

      end
    end
  end
end

