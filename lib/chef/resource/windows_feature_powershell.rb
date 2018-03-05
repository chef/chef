#
# Author:: Greg Zapp (<greg.zapp@gmail.com>)
#
# Copyright:: 2015-2018, Chef Software, Inc
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

class Chef
  class Resource
    class WindowsFeaturePowershell < Chef::Resource
      resource_name :windows_feature_powershell
      provides :windows_feature_powershell

      description "Use the windows_feature_powershell resource to add, remove or"\
                  " delete Windows features and roles using PowerShell. This resource"\
                  " offers significant speed benefits over the windows_feature_dism resource,"\
                  " but requires installing the Remote Server Administration Tools on"\
                  " non-server releases of Windows"
      introduced "14.0"

      property :feature_name, [Array, String],
               description: "The name of the feature/role(s) to install if it differs from the resource name.",
               coerce: proc { |x| Array(x) },
               name_property: true

      property :source, String,
               description: "Use a local repository for the feature install."

      property :all, [true, false],
               description: "Install all sub features. This is equivalent to using the"\
                            " -InstallAllSubFeatures switch with Add-WindowsFeature.",
               default: false

      property :timeout, Integer,
               description: "Specifies a timeout (in seconds) for feature install.",
               default: 600

      property :management_tools, [true, false],
               description: "",
               default: false

      include Chef::Mixin::PowershellOut

      action :install do
        description "Install a Windows role/feature using PowerShell"

        Chef::Log.warn("Requested feature #{new_resource.feature_name.join(',')} is not available on this system.") unless available?
        unless !available? || installed?
          converge_by("install Windows feature#{'s' if new_resource.feature_name.count > 1} #{new_resource.feature_name.join(',')}") do
            addsource = new_resource.source ? "-Source \"#{new_resource.source}\"" : ""
            addall = new_resource.all ? "-IncludeAllSubFeature" : ""
            addmanagementtools = new_resource.management_tools ? "-IncludeManagementTools" : ""
            cmd = if node["os_version"].to_f < 6.2
                    powershell_out!("#{install_feature_cmdlet} #{new_resource.feature_name.join(',')} #{addall}", timeout: new_resource.timeout)
                  else
                    powershell_out!("#{install_feature_cmdlet} #{new_resource.feature_name.join(',')} #{addsource} #{addall} #{addmanagementtools}", timeout: new_resource.timeout)
                  end
            Chef::Log.info(cmd.stdout)
          end
        end
      end

      action :remove do
        description "Remove a Windows role/feature using PowerShell"

        if installed?
          converge_by("remove Windows feature#{'s' if new_resource.feature_name.count > 1} #{new_resource.feature_name.join(',')}") do
            cmd = powershell_out!("#{remove_feature_cmdlet} #{new_resource.feature_name.join(',')}", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)
          end
        end
      end

      action :delete do
        description "Remove a Windows role/feature from the image using Powershell"

        if available?
          converge_by("delete Windows feature#{'s' if new_resource.feature_name.count > 1} #{new_resource.feature_name.join(',')} from the image") do
            cmd = powershell_out!("Uninstall-WindowsFeature #{new_resource.feature_name.join(',')} -Remove", timeout: new_resource.timeout)
            Chef::Log.info(cmd.stdout)
          end
        end
      end

      action_class do
        # @todo remove this when we're ready to drop windows 8/2012
        def install_feature_cmdlet
          node["os_version"].to_f < 6.2 ? "Import-Module ServerManager; Add-WindowsFeature" : "Install-WindowsFeature"
        end

        # @todo remove this when we're ready to drop windows 8/2012
        def remove_feature_cmdlet
          node["os_version"].to_f < 6.2 ? "Import-Module ServerManager; Remove-WindowsFeature" : "Uninstall-WindowsFeature"
        end

        def installed?
          @installed ||= begin
            # @todo remove this when we're ready to drop windows 8/2012
            cmd = if node["os_version"].to_f < 6.2
                    powershell_out("Import-Module ServerManager; @(Get-WindowsFeature #{new_resource.feature_name.join(',')} | ?{$_.Installed -ne $TRUE}).count", timeout: new_resource.timeout)
                  else
                    powershell_out("@(Get-WindowsFeature #{new_resource.feature_name.join(',')} | ?{$_.InstallState -ne \'Installed\'}).count", timeout: new_resource.timeout)
                  end
            cmd.stderr.empty? && cmd.stdout.chomp.to_i == 0
          end
        end

        def available?
          @available ||= begin
            # @todo remove this when we're ready to drop windows 8/2012
            cmd = if node["os_version"].to_f < 6.2
                    powershell_out("Import-Module ServerManager; @(Get-WindowsFeature #{new_resource.feature_name.join(',')}).count", timeout: new_resource.timeout)
                  else
                    powershell_out("@(Get-WindowsFeature #{new_resource.feature_name.join(',')} | ?{$_.InstallState -ne \'Removed\'}).count", timeout: new_resource.timeout)
                  end
            cmd.stderr.empty? && cmd.stdout.chomp.to_i > 0
          end
        end
      end
    end
  end
end
