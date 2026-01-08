#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "../mixin/homebrew"

class Chef
  class Resource
    class HomebrewTap < Chef::Resource

      provides(:homebrew_tap) { true }

      description "Use the **homebrew_tap** resource to add additional formula repositories to the Homebrew package manager."
      introduced "14.0"

      examples <<~DOC
      **Tap a repository**:

      ```ruby
      homebrew_tap 'apple/homebrew-apple'
      ```
      DOC

      include Chef::Mixin::Homebrew

      property :tap_name, String,
        description: "An optional property to set the tap name if it differs from the resource block's name.",
        validation_message: "Homebrew tap names must be in the form REPO/TAP format!",
        regex: %r{^[\w-]+(?:\/[\w-]+)+$},
        name_property: true

      property :url, String,
        description: "The URL of the tap."

      property :homebrew_path, String,
        description: "The path to the Homebrew binary."

      property :owner, String,
        description: "The owner of the Homebrew installation.",
        default: lazy { find_homebrew_username },
        default_description: "Calculated default username"

      action :tap, description: "Add a Homebrew tap." do
        unless tapped?(new_resource.tap_name)
          converge_by("tap #{new_resource.tap_name}") do
            execute "tap #{new_resource.tap_name}" do
              command "#{homebrew_bin_path(new_resource.homebrew_path)} tap #{new_resource.tap_name} #{new_resource.url || ""}"
              user new_resource.owner
              default_env true
              cwd ::Dir.home(new_resource.owner)
              login true
            end
          end
        end
      end

      action :untap, description: "Remove a Homebrew tap." do
        if tapped?(new_resource.tap_name)
          converge_by("untap #{new_resource.tap_name}") do
            execute "untap #{new_resource.tap_name}" do
              command "#{homebrew_bin_path(new_resource.homebrew_path)} untap #{new_resource.tap_name}"
              user new_resource.owner
              default_env true
              cwd ::Dir.home(new_resource.owner)
              login true
            end
          end
        end
      end

      action_class do
        # Check if the passed tap is already tapped
        #
        # @return [Boolean]
        def tapped?(name)
          brew_path = ::File.dirname(homebrew_bin_path(new_resource.homebrew_path))
          base_path = [
            "#{brew_path}/../homebrew",
            "#{brew_path}/../Homebrew",
            "/opt/homebrew",
            "/usr/local/Homebrew",
            "/home/linuxbrew/.linuxbrew",
          ].select { |x| Dir.exist?(x) }.first
          tap_dir = name.gsub("/", "/homebrew-")
          ::File.directory?("#{base_path}/Library/Taps/#{tap_dir}")
        end
      end
    end
  end
end
