# Author:: Tor Magnus Rakvåg (tm@intility.no)
# Copyright:: 2018, Intility AS
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

require_relative "../resource"

class Chef
  class Resource
    class PowershellPackageSource < Chef::Resource
      unified_mode true

      provides :powershell_package_source

      description "Use the **powershell_package_source** resource to register a PowerShell package repository."
      introduced "14.3"

      property :source_name, String,
        description: "The name of the package source.",
        name_property: true

      property :url, String,
        description: "The URL to the package source.",
        required: [:register]

      property :trusted, [TrueClass, FalseClass],
        description: "Whether or not to trust packages from this source.",
        default: false

      property :provider_name, String,
        equal_to: %w{ Programs msi NuGet msu PowerShellGet psl chocolatey },
        validation_message: "The following providers are supported: 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl' or 'chocolatey'",
        description: "The package management provider for the source.",
        default: "NuGet"

      property :publish_location, String,
        description: "The URL where modules will be published to for this source. Only valid if the provider is `PowerShellGet`."

      property :script_source_location, String,
        description: "The URL where scripts are located for this source. Only valid if the provider is `PowerShellGet`."

      property :script_publish_location, String,
        description: "The location where scripts will be published to for this source. Only valid if the provider is `PowerShellGet`."

      load_current_value do
        cmd = load_resource_state_script(source_name)
        repo = powershell_exec!(cmd)
        if repo.result.empty?
          current_value_does_not_exist!
        else
          status = repo.result
        end
        url status["url"]
        trusted status["trusted"]
        provider_name status["provider_name"]
        publish_location status["publish_location"]
        script_source_location status["script_source_location"]
        script_publish_location status["script_publish_location"]
      end

      action :register, description: "Registers and updates the PowerShell package source." do
        # TODO: Ensure package provider is installed?
        if psrepository_cmdlet_appropriate?
          if package_source_exists?
            converge_if_changed :url, :trusted, :publish_location, :script_source_location, :script_publish_location do
              update_cmd = build_ps_repository_command("Set", new_resource)
              res = powershell_exec(update_cmd)
              raise "Failed to update #{new_resource.source_name}: #{res.errors}" if res.error?
            end
          else
            converge_by("register source: #{new_resource.source_name}") do
              register_cmd = build_ps_repository_command("Register", new_resource)
              res = powershell_exec(register_cmd)
              raise "Failed to register #{new_resource.source_name}: #{res.errors}" if res.error?
            end
          end
        else
          if package_source_exists?
            converge_if_changed :url, :trusted, :provider_name do
              update_cmd = build_package_source_command("Set", new_resource)
              res = powershell_exec(update_cmd)
              raise "Failed to update #{new_resource.source_name}: #{res.errors}" if res.error?
            end
          else
            converge_by("register source: #{new_resource.source_name}") do
              register_cmd = build_package_source_command("Register", new_resource)
              res = powershell_exec(register_cmd)
              raise "Failed to register #{new_resource.source_name}: #{res.errors}" if res.error?
            end
          end
        end
      end

      action :unregister, description: "Unregisters the PowerShell package source." do
        if package_source_exists?
          unregister_cmd = "Get-PackageSource -Name '#{new_resource.source_name}' | Unregister-PackageSource"
          converge_by("unregister source: #{new_resource.source_name}") do
            res = powershell_exec(unregister_cmd)
            raise "Failed to unregister #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        end
      end

      action_class do
        def package_source_exists?
          cmd = powershell_exec!("(Get-PackageSource -Name '#{new_resource.source_name}' -ErrorAction SilentlyContinue).Name")
          !cmd.result.empty? && cmd.result.to_s.downcase.strip == new_resource.source_name.downcase
        end

        def psrepository_cmdlet_appropriate?
          new_resource.provider_name == "PowerShellGet"
        end

        def build_ps_repository_command(cmdlet_type, new_resource)
          cmd = "#{cmdlet_type}-PSRepository -Name '#{new_resource.source_name}'"
          cmd << " -SourceLocation '#{new_resource.url}'" if new_resource.url
          cmd << " -InstallationPolicy '#{new_resource.trusted ? "Trusted" : "Untrusted"}'"
          cmd << " -PublishLocation '#{new_resource.publish_location}'" if new_resource.publish_location
          cmd << " -ScriptSourceLocation '#{new_resource.script_source_location}'" if new_resource.script_source_location
          cmd << " -ScriptPublishLocation '#{new_resource.script_publish_location}'" if new_resource.script_publish_location
          cmd << " | Out-Null"
          cmd
        end

        def build_package_source_command(cmdlet_type, new_resource)
          cmd = "#{cmdlet_type}-PackageSource -Name '#{new_resource.source_name}'"
          cmd << " -Location '#{new_resource.url}'" if new_resource.url
          cmd << " -Trusted:#{new_resource.trusted ? "$true" : "$false"}"
          cmd << " -ProviderName '#{new_resource.provider_name}'" if new_resource.provider_name
          cmd << " | Out-Null"
          cmd
        end
      end
    end

    private

    def load_resource_state_script(name)
      <<-EOH
        $PSDefaultParameterValues = @{
          "*:WarningAction" = "SilentlyContinue"
        }
        if(Get-PackageSource -Name '#{name}' -ErrorAction SilentlyContinue) {
            if ((Get-PackageSource -Name '#{name}').ProviderName -eq 'PowerShellGet') {
                (Get-PSRepository -Name '#{name}') | Select @{n='source_name';e={$_.Name}}, @{n='url';e={$_.SourceLocation}},
                @{n='trusted';e={$_.Trusted}}, @{n='provider_name';e={$_.PackageManagementProvider}}, @{n='publish_location';e={$_.PublishLocation}},
                @{n='script_source_location';e={$_.ScriptSourceLocation}}, @{n='script_publish_location';e={$_.ScriptPublishLocation}}
            }
            else {
                (Get-PackageSource -Name '#{name}') | Select @{n='source_name';e={$_.Name}}, @{n='url';e={$_.Location}},
                @{n='provider_name';e={$_.ProviderName}}, @{n='trusted';e={$_.IsTrusted}}
            }
        }
      EOH
    end
  end
end
