#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"
require_relative "../mixin/homebrew_user"

class Chef
  class Resource
    class HomebrewTap < Chef::Resource
      unified_mode true

      provides(:homebrew_tap) { true }

      description "Use the **homebrew_tap** resource to add additional formula repositories to the Homebrew package manager."
      introduced "14.0"

      include Chef::Mixin::HomebrewUser

      property :tap_name, String,
        description: "An optional property to set the tap name if it differs from the resource block's name.",
        validation_message: "Homebrew tap names must be in the form REPO/TAP format!",
        regex: %r{^[\w-]+(?:\/[\w-]+)+$},
        name_property: true

      property :url, String,
        description: "The URL of the tap."

      property :full, [TrueClass, FalseClass],
        description: "Perform a full clone on the tap, as opposed to a shallow clone.",
        default: false

      property :homebrew_path, String,
        description: "The path to the Homebrew binary.",
        default: "/usr/local/bin/brew"

      property :owner, String,
        description: "The owner of the Homebrew installation.",
        default: lazy { find_homebrew_username },
        default_description: "Calculated default username"

      action :tap, description: "Add a Homebrew tap." do
        unless tapped?(new_resource.tap_name)
          converge_by("tap #{new_resource.tap_name}") do
            shell_out!("#{new_resource.homebrew_path} tap #{new_resource.full ? "--full" : ""} #{new_resource.tap_name} #{new_resource.url || ""}",
              user: new_resource.owner,
              env:  { "HOME" => ::Dir.home(new_resource.owner), "USER" => new_resource.owner },
              cwd: ::Dir.home(new_resource.owner))
          end
        end
      end

      action :untap, description: "Remove a Homebrew tap." do
        if tapped?(new_resource.tap_name)
          converge_by("untap #{new_resource.tap_name}") do
            shell_out!("#{new_resource.homebrew_path} untap #{new_resource.tap_name}",
              user: new_resource.owner,
              env:  { "HOME" => ::Dir.home(new_resource.owner), "USER" => new_resource.owner },
              cwd: ::Dir.home(new_resource.owner))
          end
        end
      end

      # Is the passed tap already tapped
      #
      # @return [Boolean]
      def tapped?(name)
        tap_dir = name.gsub("/", "/homebrew-")
        ::File.directory?("/usr/local/Homebrew/Library/Taps/#{tap_dir}")
      end
    end
  end
end
