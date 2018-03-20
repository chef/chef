#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: 2011-2018, Chef Software, Inc.
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

require "chef/resource"
require "chef/mixin/homebrew_user"

class Chef
  class Resource
    class HomebrewTap < Chef::Resource
      resource_name :homebrew_tap

      description "Use the homebrew_tap resource to add additional formula repositories to the Homebrew package manager."
      introduced "14.0"

      include Chef::Mixin::HomebrewUser

      property :tap_name, String,
               description: "Optional tap name to override the resource name",
               validation_message: "Homebrew tap names must be in the form REPO/TAP",
               regex: %r{^[\w-]+(?:\/[\w-]+)+$},
               name_property: true

      property :url, String,
               description: "URL to the tap."

      property :full, [TrueClass, FalseClass],
               description: "Perform a full clone rather than a shallow clone on the tap.",
               default: false

      property :homebrew_path, String,
               description: "The path to the homebrew binary.",
               default: "/usr/local/bin/brew"

      property :owner, String,
               description: "The owner of the homebrew installation",
               default: lazy { Chef::Mixin::HomebrewUser.find_homebrew_username }

      action :tap do
        description "Add a Homebrew tap."

        unless tapped?(new_resource.name)
          converge_by("tap #{new_resource.name}") do
            shell_out!("#{new_resource.homebrew_path} tap #{new_resource.full ? '--full' : ''} #{new_resource.name} #{new_resource.url || ''}",
                user: new_resource.owner,
                env:  { "HOME" => ::Dir.home(new_resource.owner), "USER" => new_resource.owner },
                cwd: ::Dir.home(new_resource.owner))
          end
        end
      end

      action :untap do
        description "Remove a Homebrew tap."

        if tapped?(new_resource.name)
          converge_by("untap #{new_resource.name}") do
            shell_out!("#{new_resource.homebrew_path} untap #{new_resource.name}",
                user: new_resource.owner,
                env:  { "HOME" => ::Dir.home(new_resource.owner), "USER" => new_resource.owner },
                cwd: ::Dir.home(new_resource.owner))
          end
        end
      end

      def tapped?(name)
        tap_dir = name.gsub("/", "/homebrew-")
        ::File.directory?("/usr/local/Homebrew/Library/Taps/#{tap_dir}")
      end
    end
  end
end
