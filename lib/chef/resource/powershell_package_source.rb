# Author:: Tor Magnus Rakvåg (tm@intility.no)
# Copyright:: 2015-2018 Chef Software, Inc.
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

class Chef
  class Resource
    class PowershellPackageSource < Chef::Resource
      resource_name "powershell_package_source"
      provides(:powershell_package_source) { true }

      description "Use the powershell_package_source resource to register a powershell package repository"
      introduced "15.0"

      property :name, String,
               description: "",
               name_property: true

      property :url, String,
               description: "",
               required: true

      property :trusted, [true, false],
               description: "",
               default: false

      property :package_management_provider, String,
               equal_to: %w{ Programs msi NuGet msu PowerShellGet psl chocolatey },
               validation_message: "The following providers are supported: 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl' or 'chocolatey'",
               description: "",
               default: "NuGet"

      property :publish_location, String,
               description: "",
               required: false

      property :script_source_location, String,
               description: "",
               required: false

      property :script_publish_location, String,
               description: "",
               required: false

      action :register do
        register_cmd = "Register-PackageSource -Name '#{new_resource.name}' -Location '#{new_resource.url}'"
        register_cmd << " -Trusted" if new_resource.trusted
        register_cmd << " -PublishLocation '#{new_resource.publish_location}'" if new_resource.publish_location
        register_cmd << " -ScriptSourceLocation '#{new_resource.script_source_location}'" if new_resource.script_source_location
        register_cmd << " -ScriptPublishLocation '#{new_resource.script_publish_location}'" if new_resource.script_publish_location
        register_cmd << " -Force -ForceBootstrap"

        powershell_script "register package source: #{new_resource.name}" do
          code register_cmd
          not_if { package_source_exists? }
        end
      end

      action :unregister do
        unregister_cmd = "Get-PackageSource -Name '#{new_resource.name}' | Unregister-PackageSource"

        powershell_script "unregister package source: #{new_resource.name}" do
          code unregister_cmd
          only_if { package_source_exists? }
        end
      end

      action_class do
        def package_source_exists?
          cmd = powershell_out!("(Get-PackageSource -Name '#{new_resource.name}').Name")
          cmd.stdout.downcase.strip == new_resource.name.downcase
        end
      end
    end
  end
end
