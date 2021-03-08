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
    class Edit < Chef::ChefFS::Knife
      banner "knife edit [PATTERN1 ... PATTERNn]"

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
        pattern_args.each do |pattern|
          Chef::ChefFS::FileSystem.list(config[:local] ? local_fs : chef_fs, pattern).each do |result|
            if result.dir?
              ui.error "#{format_path(result)}: is a directory" if pattern.exact_path
              error = true
            else
              begin
                new_value = edit_text(result.read, File.extname(result.name))
                if new_value
                  result.write(new_value)
                  output "Updated #{format_path(result)}"
                else
                  output "#{format_path(result)} unchanged"
                end
              rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
                ui.error "#{format_path(e.entry)}: #{e.reason}."
                error = true
              rescue Chef::ChefFS::FileSystem::NotFoundError => e
                ui.error "#{format_path(e.entry)}: No such file or directory"
                error = true
              end
            end
          end
        end
        if error
          exit 1
        end
      end

      def edit_text(text, extension)
        unless config[:disable_editing]
          Tempfile.open([ "knife-edit-", extension ]) do |file|
            # Write the text to a temporary file
            file.write(text)
            file.close

            # Let the user edit the temporary file
            unless system("#{config[:editor]} #{file.path}")
              raise "Please set EDITOR environment variable. See https://docs.chef.io/knife_setup/ for details."
            end

            result_text = IO.read(file.path)

            return result_text if result_text != text
          end
        end
      end
    end
  end
end
