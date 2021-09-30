# Author:: Tor Magnus Rakvåg (tm@intility.no)
# Author:: John McCrae (john.mccrae@progress.com)
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

      description "Use the **powershell_package_source** resource to register a PowerShell Repository or other Package Source type with. There are 2 distinct objects we care about here. The first is a Package Source like a PowerShell Repository or a Nuget Source. The second object is a provider that PowerShell uses to get to that source with, like PowerShellGet, Nuget, Chocolatey, etc. "
      introduced "14.3"
      examples <<~DOC
        **Add a new PSRepository that is not trusted and which requires credentials to connect to**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          source_location              "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          publish_location             "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      false
          user                         "someuser@somelocation.io"
          password                     "my_password"
          provider_name                "PSRepository"
          action                       :register
        end
        ```

        **Add a new Package Source that uses Chocolatey as the Package Provider**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          source_location              "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          publish_location             "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      true
          provider_name                "chocolatey"
          action                       :register
        end
        ```

        **Add a new PowerShell Script source that is trusted**:

        ```ruby
        powershell_package_source 'MyDodgyScript' do
          source_name                  "MyDodgyScript"
          script_source_location       "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          script_publish_location      "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      true
          action                       :register
        end
        ```

        **Update my existing PSRepository to make it Trusted after all**:

        ```ruby
        powershell_package_source 'MyPSModule' do
          source_name                  "MyPSModule"
          trusted                      true
          action                       :set
        end
        ```

        **Update a Nuget package source with a new name and make it trusted**:

        ```ruby
        powershell_package_source 'PowerShellModules -> GoldFishBowl' do
          source_name                  "PowerShellModules"
          new_name                     "GoldFishBowl"
          provider_name                "Nuget"
          trusted                      true
          action                       :set
        end
        ```

        **Update a Nuget package source with a new name when the source is secured with a username and password**:

        ```ruby
        powershell_package_source 'PowerShellModules -> GoldFishBowl' do
          source_name                  "PowerShellModules"
          new_name                     "GoldFishBowl"
          trusted                      true
          user                         "user@domain.io"
          password                     "some_secret_password"
          action                       :set
        end
        ```

        **Unregister a package source**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          action                       :unregister
        end
        ```
      DOC

      property :source_name, String,
        description: "A label that names your package source.",
        name_property: true

      property :new_name, introduced: "17.6", String,
        description: "Used to change the name of a standard PackageSource."

      property :source_location, introduced: "17.6", String,
        description: "The URL to the location to retrieve modules from."

      alias :url :source_location

      property :publish_location, String,
        description: "The URL where modules will be published to. Only valid if the provider is `PowerShellGet`."

      property :script_source_location, String,
        description: "The URL where scripts are located for this source. Only valid if the provider is `PowerShellGet`."

      property :script_publish_location, String,
        description: "The location where scripts will be published to for this source. Only valid if the provider is `PowerShellGet`."

      property :trusted, [TrueClass, FalseClass],
        description: "Whether or not to trust packages from this source. Used when creating a NON-PSRepository Package Source",
        default: false

      property :user, introduced: "17.6", String,
        description: "A username that, as part of a credential object, is used to register a repository or other package source with."

      property :password, introduced: "17.6", String,
        description: "A password that, as part of a credential object, is used to register a repository or other package source with."

      property :provider_name, String,
        equal_to: %w{ Programs msi NuGet msu PowerShellGet psl chocolatey winget },
        validation_message: "The following providers are supported: 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl', 'chocolatey' or 'winget'",
        description: "The package management provider for the package source. The default is PowerShellGet and this option need only be set otherwise in specific use cases.",
        default: "NuGet"

      load_current_value do
        cmd = load_resource_state_script(source_name)
        repo = powershell_exec!(cmd)
        if repo.result.empty?
          current_value_does_not_exist!
        else
          status = repo.result
        end
        source_name status["source_name"]
        new_name status["new_name"]
        source_location status["source_location"]
        trusted status["trusted"]
        provider_name status["provider_name"]
        publish_location status["publish_location"]
        script_source_location status["script_source_location"]
        script_publish_location status["script_publish_location"]
      end

      # Notes:
      # There are 2 objects we care about with this code. 1) The Package Provider which can be Nuget, PowerShellGet, Chocolatey, et al. 2) The PackageSource where the files we want access to live. The Package Provider gets us access to the Package Source.
      # Per the Microsoft docs you can only have one provider for one source. Enter the PSRepository. It is a sub-type of Package Source.
      # If you register a new PSRepository you get both a PSRepository object AND a Package Source object which are distinct. If you call "Get-PSRepository -Name 'PSGallery'" from powershell, notice that the Packageprovider is Nuget
      # now go execute "Get-PackageSource -Name 'PSGallery'" and notice that the PackageProvider is PowerShellGet. If you set a new PSRepository without specifying a PackageProvider ("Register-PSRepository -Name 'foo' -source...") the command will create both
      # a PackageSource and a PSRepository with different providers.

      # Unregistering a PackageSource (unregister-packagesource -name 'foo') where that source is also a PSRepository also causes that object to delete as well. This makes sense as PSRepository is a sub-type of packagesource.
      # All PSRepositories are PackageSources, and all PackageSources with Provider PowerShellGet are PSRepositories. They are 2 different views of the same object.

      action :register, description: "Registers a PowerShell package source." do
        package_details = get_package_source_details
        output = package_details.result
        if output == "PSRepository" || output == "PackageSource"
          action_set
        elsif new_resource.provider_name.downcase.strip == "powershellget"
          converge_by("register source: #{new_resource.source_name}") do
            register_cmd = build_ps_repository_command("Register", new_resource)
            res = powershell_exec(register_cmd)
            raise "Failed to register #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        else
          converge_by("register source: #{new_resource.source_name}") do
            register_cmd = build_package_source_command("Register", new_resource)
            res = powershell_exec(register_cmd)
            raise "Failed to register #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        end
      end

      action :set, description: "Updates an existing PSRepository or Package Source" do
        package_details = get_package_source_details
        output = package_details.result
        if output == "PSRepository"
          converge_if_changed :source_location, :trusted, :publish_location, :script_source_location, :script_publish_location, :source_name do
            set_cmd = build_ps_repository_command("Set", new_resource)
            res = powershell_exec(set_cmd)
            raise "Failed to Update #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        elsif output == "PackageSource"
          converge_if_changed :source_location, :trusted, :new_name, :provider_name do
            set_cmd = build_package_source_command("Set", new_resource)
            res = powershell_exec(set_cmd)
            raise "Failed to Update #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        end
      end

      action :unregister, description: "Unregisters the PowerShell package source." do
        package_details = get_package_source_details
        output = package_details.result
        if output == "PackageSource" || output == "PSRepository"
          unregister_cmd = "Unregister-PackageSource -Name '#{new_resource.source_name}'"
          converge_by("unregister source: #{new_resource.source_name}") do
            res = powershell_exec!(unregister_cmd)
            raise "Failed to unregister #{new_resource.source_name}: #{res.errors}" if res.error?
          end
        else
          logger.warn("*****************************************")
          logger.warn("Failed to unregister #{new_resource.source_name}: Package Source does not exist")
          logger.warn("*****************************************")
        end
      end

      action_class do

        def get_package_source_details
          powershell_exec! <<~EOH
              $package_details = Get-PackageSource -Name '#{new_resource.source_name}' -ErrorAction SilentlyContinue
              if ($package_details.ProviderName -match "PowerShellGet"){
                return "PSRepository"
              }
              elseif ($package_details.ProviderName ) {
                return "PackageSource"
              }
              elseif ($null -eq $package_details)
              {
                return "Unregistered"
              }
          EOH
        end

        def build_ps_repository_command(cmdlet_type, new_resource)
          if new_resource.trusted == true
            install_policy = "Trusted"
          else
            install_policy = "Untrusted"
          end
          if new_resource.user && new_resource.password
            cmd =  "$user = '#{new_resource.user}';"
            cmd << "[securestring]$secure_password = Convertto-SecureString -String '#{new_resource.password}' -AsPlainText -Force;"
            cmd << "$Credentials = New-Object System.Management.Automation.PSCredential -Argumentlist ($user, $secure_password);"
            cmd << "#{cmdlet_type}-PSRepository -Name '#{new_resource.source_name}'"
            cmd << " -SourceLocation '#{new_resource.source_location}'" if new_resource.source_location
            cmd << " -InstallationPolicy '#{install_policy}'"
            cmd << " -PublishLocation '#{new_resource.publish_location}'" if new_resource.publish_location
            cmd << " -ScriptSourceLocation '#{new_resource.script_source_location}'" if new_resource.script_source_location
            cmd << " -ScriptPublishLocation '#{new_resource.script_publish_location}'" if new_resource.script_publish_location
            cmd << " -Credential $Credentials"
            cmd << " | Out-Null"
          else
            cmd = "#{cmdlet_type}-PSRepository -Name '#{new_resource.source_name}'"
            cmd << " -SourceLocation '#{new_resource.source_location}'" if new_resource.source_location
            cmd << " -InstallationPolicy '#{install_policy}'"
            cmd << " -PublishLocation '#{new_resource.publish_location}'" if new_resource.publish_location
            cmd << " -ScriptSourceLocation '#{new_resource.script_source_location}'" if new_resource.script_source_location
            cmd << " -ScriptPublishLocation '#{new_resource.script_publish_location}'" if new_resource.script_publish_location
            cmd << " | Out-Null"
          end
          cmd
        end

        def build_package_source_command(cmdlet_type, new_resource)
          if new_resource.user && new_resource.password
            cmd =  "$user = '#{new_resource.user}';"
            cmd << "[securestring]$secure_password = Convertto-SecureString -String '#{new_resource.password}' -AsPlainText -Force;"
            cmd << "$Credentials = New-Object System.Management.Automation.PSCredential -Argumentlist ($user, $secure_password);"
            cmd << "#{cmdlet_type}-PackageSource -Name '#{new_resource.source_name}'"
            cmd << " -Location '#{new_resource.source_location}'" if new_resource.source_location
            cmd << " -Trusted" if new_resource.trusted
            cmd << " -ProviderName '#{new_resource.provider_name}'" if new_resource.provider_name
            cmd << " -Credential $credentials"
            cmd << " | Out-Null"
            cmd
          else
            cmd = "#{cmdlet_type}-PackageSource -Name '#{new_resource.source_name}'"
            cmd << " -NewName '#{new_resource.new_name}'" if new_resource.new_name
            cmd << " -Location '#{new_resource.source_location}'" if new_resource.source_location
            cmd << " -Trusted" if new_resource.trusted
            cmd << " -ProviderName '#{new_resource.provider_name}'" if new_resource.provider_name
            cmd << " | Out-Null"
            cmd
          end
        end
      end
    end

    private

    def load_resource_state_script(source_name)
      <<-EOH
        $PSDefaultParameterValues = @{
          "*:WarningAction" = "SilentlyContinue"
        }
        if(Get-PackageSource -Name '#{source_name}' -ErrorAction SilentlyContinue) {
            if ((Get-PackageSource -Name '#{source_name}').ProviderName -eq 'PowerShellGet') {
                (Get-PSRepository -Name '#{source_name}') | Select @{n='source_name';e={$_.Name}}, @{n='source_location';e={$_.SourceLocation}},
                @{n='trusted';e={$_.Trusted}}, @{n='provider_name';e={$_.PackageManagementProvider}}, @{n='publish_location';e={$_.PublishLocation}},
                @{n='script_source_location';e={$_.ScriptSourceLocation}}, @{n='script_publish_location';e={$_.ScriptPublishLocation}}
            }
            else {
                (Get-PackageSource -Name '#{source_name}') | Select @{n='source_name';e={$_.Name}}, @{n='new_name';e={$_.Name}}, @{n='source_location';e={$_.Location}},
                @{n='provider_name';e={$_.ProviderName}}, @{n='trusted';e={$_.IsTrusted}}, @{n='publish_location';e={$_.PublishLocation}}
            }
        }
      EOH
    end
  end
end
