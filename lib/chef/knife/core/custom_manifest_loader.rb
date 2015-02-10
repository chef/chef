# Author:: Steven Danna (<steve@chef.io>)
# Copyright:: Copyright (c) 2015 Chef Software, Inc
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

require 'chef/version'
class Chef
  class Knife
    class SubcommandLoader

      #
      # Load a subcommand from a user-supplied
      # manifest file
      #
      class CustomManifestLoader < Chef::Knife::SubcommandLoader
        attr_accessor :manifest
        def initialize(chef_config_dir, plugin_manifest)
          super(chef_config_dir)
          @manifest = plugin_manifest
        end

        # If the user has created a ~/.chef/plugin_manifest.json file, we'll use
        # that instead of inspecting the on-system gems to find the plugins. The
        # file format is expected to look like:
        #
        #   { "plugins": {
        #       "knife-ec2": {
        #         "paths": [
        #           "/home/alice/.rubymanagerthing/gems/knife-ec2-x.y.z/lib/chef/knife/ec2_server_create.rb",
        #           "/home/alice/.rubymanagerthing/gems/knife-ec2-x.y.z/lib/chef/knife/ec2_server_delete.rb"
        #         ]
        #       }
        #     }
        #   }
        #
        # Extraneous content in this file is ignored. This intentional so that we
        # can adapt the file format for potential behavior changes to knife in
        # the future.
        def find_subcommands_via_manifest
          # Format of subcommand_files is "relative_path" (something you can
          # Kernel.require()) => full_path. The relative path isn't used
          # currently, so we just map full_path => full_path.
          subcommand_files = {}
          manifest["plugins"].each do |plugin_name, plugin_manifest|
            plugin_manifest["paths"].each do |cmd_path|
              subcommand_files[cmd_path] = cmd_path
            end
          end
          subcommand_files.merge(find_subcommands_via_dirglob)
        end

        def subcommand_files
          subcommand_files ||= (find_subcommands_via_manifest.values + site_subcommands).flatten.uniq
        end
      end
    end
  end
end
