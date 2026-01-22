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
    class HomebrewCask < Chef::Resource

      provides(:homebrew_cask) { true }

      description "Use the **homebrew_cask** resource to install binaries distributed via the Homebrew package manager."
      introduced "14.0"

      include Chef::Mixin::Homebrew

      property :cask_name, String,
        description: "An optional property to set the cask name if it differs from the resource block's name.",
        regex: %r{^[\w/\-@]+$},
        validation_message: "The provided Homebrew cask name is not valid. Cask names can contain alphanumeric characters, _, -, or / only!",
        name_property: true

      property :options, String,
        description: "Options to pass to the brew command during installation."

      property :homebrew_path, String,
        description: "The path to the Homebrew binary."

      property :owner, [String, Integer],
        description: "The owner of the Homebrew installation.",
        default: lazy { find_homebrew_username },
        default_description: "Calculated default username" \

      action :install, description: "Install an application that is packaged as a Homebrew cask." do
        unless casked?
          converge_by("install cask #{new_resource.cask_name} #{new_resource.options}") do
            execute "install cask #{new_resource.cask_name}" do
              command "#{homebrew_bin_path(new_resource.homebrew_path)} install --cask #{new_resource.cask_name} #{new_resource.options}"
              user new_resource.owner
              cwd ::Dir.home(new_resource.owner)
              login true
            end
          end
        end
      end

      action :remove, description: "Remove an application that is packaged as a Homebrew cask." do
        if casked?
          converge_by("uninstall cask #{new_resource.cask_name}") do
            execute "uninstall cask #{new_resource.cask_name}" do
              command "#{homebrew_bin_path(new_resource.homebrew_path)} uninstall --cask #{new_resource.cask_name}"
              user new_resource.owner
              cwd ::Dir.home(new_resource.owner)
              login true
            end
          end
        end
      end

      action_class do
        alias_method :action_cask, :action_install
        alias_method :action_uncask, :action_remove
        alias_method :action_uninstall, :action_remove

        # Is the desired cask already casked?
        #
        # @return [Boolean]
        def casked?
          unscoped_name = new_resource.cask_name.split("/").last
          shell_out!(
            "#{homebrew_bin_path(new_resource.homebrew_path)} list --cask 2>/dev/null",
            user: new_resource.owner,
            env:  { "HOME" => ::Dir.home(new_resource.owner), "USER" => new_resource.owner },
            cwd: ::Dir.home(new_resource.owner),
            login: true
          ).stdout.split.include?(unscoped_name)
        end
      end
    end
  end
end
