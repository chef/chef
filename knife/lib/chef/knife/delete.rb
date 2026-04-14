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
    class Delete < Chef::ChefFS::Knife
      banner "knife delete [PATTERN1 ... PATTERNn]"

      category "path-based"

      deps do
        require "chef/chef_fs/file_system" unless defined?(Chef::ChefFS::FileSystem)
      end

      option :recurse,
        short: "-r",
        long: "--[no-]recurse",
        boolean: true,
        default: false,
        description: "Delete directories recursively."

      option :both,
        long: "--both",
        boolean: true,
        default: false,
        description: "Delete both the local and remote copies."

      option :local,
        long: "--local",
        boolean: true,
        default: false,
        description: "Delete the local copy (leave the remote copy)."

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must specify at least one argument. If you want to delete everything in this directory, run \"knife delete --recurse .\"")
          exit 1
        end

        # Get the matches (recursively)
        error = false
        if config[:local]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(local_fs, pattern).each do |result|
              if delete_result(result)
                error = true
              end
            end
          end
        elsif config[:both]
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list_pairs(pattern, chef_fs, local_fs).each do |chef_result, local_result|
              if delete_result(chef_result, local_result)
                error = true
              end
            end
          end
        else # Remote only
          pattern_args.each do |pattern|
            Chef::ChefFS::FileSystem.list(chef_fs, pattern).each do |result|
              if delete_result(result)
                error = true
              end
            end
          end
        end

        if error
          exit 1
        end
      end

      def format_path_with_root(entry)
        root = entry.root == chef_fs ? " (remote)" : " (local)"
        "#{format_path(entry)}#{root}"
      end

      def delete_result(*results)
        deleted_any = false
        found_any = false
        error = false
        results.each do |result|

          result.delete(config[:recurse])
          deleted_any = true
          found_any = true
        rescue Chef::ChefFS::FileSystem::NotFoundError
          # This is not an error unless *all* of them were not found
        rescue Chef::ChefFS::FileSystem::MustDeleteRecursivelyError => e
          ui.error "#{format_path_with_root(e.entry)} must be deleted recursively!  Pass -r to knife delete."
          found_any = true
          error = true
        rescue Chef::ChefFS::FileSystem::OperationNotAllowedError => e
          ui.error "#{format_path_with_root(e.entry)} #{e.reason}."
          found_any = true
          error = true

        end
        if deleted_any
          output("Deleted #{format_path(results[0])}")
        elsif !found_any
          ui.error "#{format_path(results[0])}: No such file or directory"
          error = true
        end
        error
      end
    end
  end
end
