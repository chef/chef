#
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

require_relative "../chef_fs/knife"

class Chef
  class Knife
    class Show < Chef::ChefFS::Knife
      banner "knife show [PATTERN1 ... PATTERNn] (options)"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system" unless defined?(Chef::ChefFS::FileSystem)
        require "chef/chef_fs/file_system/exceptions" unless defined?(Chef::ChefFS::FileSystem::Exceptions)
      end

      option :local,
        long: "--local",
        boolean: true,
        description: "Show local files instead of remote."

      def run
        # Get the matches (recursively)
        error = false
        entry_values = parallelize(pattern_args) do |pattern|
          parallelize(Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern)) do |entry|
            if entry.dir?
              ui.error "#{format_path(entry)}: is a directory" if pattern.exact_path
              error = true
              nil
            else
              begin
                [entry, entry.read]
              rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
                ui.error "#{format_path(e.entry)}: #{e.reason}."
                error = true
                nil
              rescue Chef::ChefFS::FileSystem::NotFoundError => e
                ui.error "#{format_path(e.entry)}: No such file or directory"
                error = true
                nil
              end
            end
          end
        end.flatten(1)
        entry_values.each do |entry, value|
          if entry
            output "#{format_path(entry)}:"
            output(format_for_display(value))
          end
        end
        if error
          exit 1
        end
      end
    end
  end
end
