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
    class Upload < Chef::ChefFS::Knife
      banner "knife upload PATTERNS (options)"

      category "path-based"

      deps do
        require "chef/chef_fs/command_line" unless defined?(Chef::ChefFS::CommandLine)
      end

      option :recurse,
        long: "--[no-]recurse",
        boolean: true,
        default: true,
        description: "List directories recursively."

      option :purge,
        long: "--[no-]purge",
        boolean: true,
        default: false,
        description: "Delete matching local files and directories that do not exist remotely."

      option :force,
        long: "--[no-]force",
        boolean: true,
        default: false,
        description: "Force upload of files even if they match (quicker for many files). Will overwrite frozen cookbooks."

      option :freeze,
        long: "--[no-]freeze",
        boolean: true,
        default: false,
        description: "Freeze cookbooks that get uploaded."

      option :dry_run,
        long: "--dry-run",
        short: "-n",
        boolean: true,
        default: false,
        description: "Don't take action, only print what would happen."

      option :diff,
        long: "--[no-]diff",
        boolean: true,
        default: true,
        description: "Turn off to avoid uploading existing files; only new (and possibly deleted) files with --no-diff."

      def run
        if name_args.length == 0
          show_usage
          ui.fatal("You must specify at least one argument. If you want to upload everything in this directory, run \"knife upload .\"")
          exit 1
        end

        error = false
        pattern_args.each do |pattern|
          if Chef::ChefFS::FileSystem.copy_to(pattern, local_fs, chef_fs, config[:recurse] ? nil : 1, config, ui, proc { |entry| format_path(entry) })
            error = true
          end
        end
        if error
          exit 1
        end
      end
    end
  end
end
