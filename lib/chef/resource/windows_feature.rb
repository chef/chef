#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require_relative "../resource"

class Chef
  class Resource
    class WindowsFeature < Chef::Resource
      resource_name :windows_feature
      provides(:windows_feature) { true }

      description "Use the windows_feature resource to add, remove or entirely delete Windows features and roles. This resource calls the 'windows_feature_dism' or 'windows_feature_powershell' resources depending on the specified installation method and defaults to dism, which is available on both Workstation and Server editions of Windows."
      introduced "14.0"

      property :feature_name, [Array, String],
               description: "The name of the feature(s) or role(s) to install if they differ from the resource block's name. The same feature may have different names depending on the underlying installation method being used (ie DHCPServer vs DHCP; DNS-Server-Full-Role vs DNS).",
               name_property: true

      property :source, String,
               description: "Specify a local repository for the feature install."

      property :all, [TrueClass, FalseClass],
               description: "Install all sub features.",
               default: false

      property :management_tools, [TrueClass, FalseClass],
               description: "Install all applicable management tools for the roles, role services, or features (PowerShell-only).",
               default: false

      property :install_method, Symbol,
               description: "The underlying installation method to use for feature installation. Specify ':windows_feature_dism' for DISM or ':windows_feature_powershell' for PowerShell.",
               equal_to: [:windows_feature_dism, :windows_feature_powershell, :windows_feature_servermanagercmd],
               default: :windows_feature_dism

      property :timeout, Integer,
               description: "Specifies a timeout (in seconds) for the feature installation.",
               default: 600

      action :install do
        description "Install a Windows role/feature"

        run_default_subresource :install
      end

      action :remove do
        description "Remove a Windows role/feature"

        run_default_subresource :remove
      end

      action :delete do
        description "Remove a Windows role/feature from the image"

        run_default_subresource :delete
      end

      action_class do
        # call the appropriate windows_feature resource based on the specified subresource
        # @return [void]
        def run_default_subresource(desired_action)
          raise "Support for Windows feature installation via servermanagercmd.exe has been removed as this support is no longer needed in Windows 2008 R2 and above. You will need to update your recipe to install either via dism or powershell (preferred)." if new_resource.install_method == :windows_feature_servermanagercmd

          declare_resource(new_resource.install_method, new_resource.name) do
            action desired_action
            feature_name new_resource.feature_name
            source new_resource.source if new_resource.source
            all new_resource.all
            timeout new_resource.timeout
            management_tools new_resource.management_tools if new_resource.install_method == :windows_feature_powershell
          end
        end
      end
    end
  end
end
