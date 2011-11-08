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

class Chef
  class Knife
    module Core
      class ObjectLoader

        attr_reader :ui
        attr_reader :klass

        def initialize(klass, ui)
          @klass = klass
          @ui = ui
        end

        def load_from(repo_location, *components)
          unless object_file = find_file(repo_location, *components)
            ui.error "Could not find or open file for #{components.join(' ')}"
            exit 1
          end
          object_from_file(object_file)
        end

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

        def object_from_file(filename)
          case filename
          when /\.(js|json)$/
            Chef::JSONCompat.from_json(IO.read(filename))
          when /\.rb$/
            r = klass.new
            r.from_file(filename)
            r
          else
            ui.fatal("File must end in .js, .json, or .rb")
            exit 30
          end
        end

        def file_exists_and_is_readable?(file)
          File.exists?(file) && File.readable?(file)
        end

      end
    end
  end
end

