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

require "spec_helper"

describe Chef::Resource::PowershellPackageSource do
  let(:resource) { Chef::Resource::PowershellPackageSource.new("MyGallery") }
  let(:provider) { resource.provider_for_action(:enable) }

  it "has a resource name of :powershell_package_source" do
    expect(resource.resource_name).to eql(:powershell_package_source)
  end

  it "the name_property is 'name'" do
    expect(resource.source_name).to eql("MyGallery")
  end

  it "the default action is :register" do
    expect(resource.action).to eql([:register])
  end

  it "supports :register and :unregister actions" do
    expect { resource.action :register }.not_to raise_error
    expect { resource.action :unregister }.not_to raise_error
  end

  it "the url property accepts strings" do
    resource.url("https://mygallery.company.co/api/v2/")
    expect(resource.url).to eql("https://mygallery.company.co/api/v2/")
  end

  it "the trusted property accepts true and false" do
    resource.trusted(false)
    expect(resource.trusted).to eql(false)
    resource.trusted(true)
    expect(resource.trusted).to eql(true)
  end

  it "trusted defaults to false" do
    expect(resource.trusted).to eql(false)
  end

  it "provider_name accepts 'Programs', 'msi', 'NuGet', 'msu', 'PowerShellGet', 'psl', 'chocolatey'" do
    expect { resource.provider_name("Programs") }.not_to raise_error
    expect { resource.provider_name("msi") }.not_to raise_error
    expect { resource.provider_name("NuGet") }.not_to raise_error
    expect { resource.provider_name("msu") }.not_to raise_error
    expect { resource.provider_name("PowerShellGet") }.not_to raise_error
    expect { resource.provider_name("psl") }.not_to raise_error
    expect { resource.provider_name("chocolatey") }.not_to raise_error
  end

  it "the publish_location property accepts strings" do
    resource.publish_location("https://mygallery.company.co/api/v2/package")
    expect(resource.publish_location).to eql("https://mygallery.company.co/api/v2/package")
  end

  it "the script_source_location property accepts strings" do
    resource.publish_location("https://mygallery.company.co/api/v2/scripts")
    expect(resource.publish_location).to eql("https://mygallery.company.co/api/v2/scripts")
  end

  it "the script_publish_location property accepts strings" do
    resource.publish_location("https://mygallery.company.co/api/v2/scripts")
    expect(resource.publish_location).to eql("https://mygallery.company.co/api/v2/scripts")
  end

  describe "#build_ps_repository_command" do
    before do
      resource.source_name("MyGallery")
      resource.url("https://mygallery.company.co/api/v2/")
    end

    context "#register" do
      it "builds a minimal command" do
        expect(provider.build_ps_repository_command("Register", resource)).to eql("Register-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' | Out-Null")
      end

      it "builds a command with trusted set to true" do
        resource.trusted(true)
        expect(provider.build_ps_repository_command("Register", resource)).to eql("Register-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Trusted' | Out-Null")
      end

      it "builds a command with a publish location" do
        resource.publish_location("https://mygallery.company.co/api/v2/package")
        expect(provider.build_ps_repository_command("Register", resource)).to eql("Register-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -PublishLocation 'https://mygallery.company.co/api/v2/package' | Out-Null")
      end

      it "builds a command with a script source location" do
        resource.script_source_location("https://mygallery.company.co/api/v2/scripts")
        expect(provider.build_ps_repository_command("Register", resource)).to eql("Register-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -ScriptSourceLocation 'https://mygallery.company.co/api/v2/scripts' | Out-Null")
      end

      it "builds a command with a script publish location" do
        resource.script_publish_location("https://mygallery.company.co/api/v2/scripts/package")
        expect(provider.build_ps_repository_command("Register", resource)).to eql("Register-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -ScriptPublishLocation 'https://mygallery.company.co/api/v2/scripts/package' | Out-Null")
      end
    end

    context "#set" do
      it "builds a minimal command" do
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' | Out-Null")
      end

      it "builds a command to change the url" do
        resource.url("https://othergallery.company.co/api/v2/")
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://othergallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' | Out-Null")
      end

      it "builds a command with trusted set to true" do
        resource.trusted(true)
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Trusted' | Out-Null")
      end

      it "builds a command with a publish location" do
        resource.publish_location("https://mygallery.company.co/api/v2/package")
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -PublishLocation 'https://mygallery.company.co/api/v2/package' | Out-Null")
      end

      it "builds a command with a script source location" do
        resource.script_source_location("https://mygallery.company.co/api/v2/scripts")
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -ScriptSourceLocation 'https://mygallery.company.co/api/v2/scripts' | Out-Null")
      end

      it "builds a command with a script publish location" do
        resource.script_publish_location("https://mygallery.company.co/api/v2/scripts/package")
        expect(provider.build_ps_repository_command("Set", resource)).to eql("Set-PSRepository -Name 'MyGallery' -SourceLocation 'https://mygallery.company.co/api/v2/' -InstallationPolicy 'Untrusted' -ScriptPublishLocation 'https://mygallery.company.co/api/v2/scripts/package' | Out-Null")
      end
    end
  end

  describe "#build_package_source_command" do
    before do
      resource.source_name("NuGet")
      resource.url("http://nuget.org/api/v2/")
    end

    context "#register" do
      it "builds a minimal command" do
        expect(provider.build_package_source_command("Register", resource)).to eql("Register-PackageSource -Name 'NuGet' -Location 'http://nuget.org/api/v2/' -Trusted:$false -ProviderName 'NuGet' | Out-Null")
      end

      it "builds a command with trusted set to true" do
        resource.trusted(true)
        expect(provider.build_package_source_command("Register", resource)).to eql("Register-PackageSource -Name 'NuGet' -Location 'http://nuget.org/api/v2/' -Trusted:$true -ProviderName 'NuGet' | Out-Null")
      end

      it "builds a command with a different provider" do
        resource.source_name("choco")
        resource.url("https://chocolatey.org/api/v2/")
        resource.provider_name("chocolatey")
        expect(provider.build_package_source_command("Register", resource)).to eql("Register-PackageSource -Name 'choco' -Location 'https://chocolatey.org/api/v2/' -Trusted:$false -ProviderName 'chocolatey' | Out-Null")
      end
    end

    context "#set" do
      it "builds a minimal command" do
        expect(provider.build_package_source_command("Set", resource)).to eql("Set-PackageSource -Name 'NuGet' -Location 'http://nuget.org/api/v2/' -Trusted:$false -ProviderName 'NuGet' | Out-Null")
      end

      it "builds a command to change the url" do
        resource.url("https://nuget.company.co/api/v2/")
        expect(provider.build_package_source_command("Set", resource)).to eql("Set-PackageSource -Name 'NuGet' -Location 'https://nuget.company.co/api/v2/' -Trusted:$false -ProviderName 'NuGet' | Out-Null")
      end

      it "builds a command with trusted set to true" do
        resource.trusted(true)
        expect(provider.build_package_source_command("Set", resource)).to eql("Set-PackageSource -Name 'NuGet' -Location 'http://nuget.org/api/v2/' -Trusted:$true -ProviderName 'NuGet' | Out-Null")
      end

      it "builds a command with a different provider" do
        resource.source_name("choco")
        resource.url("https://chocolatey.org/api/v2/")
        resource.provider_name("chocolatey")
        expect(provider.build_package_source_command("Set", resource)).to eql("Set-PackageSource -Name 'choco' -Location 'https://chocolatey.org/api/v2/' -Trusted:$false -ProviderName 'chocolatey' | Out-Null")
      end
    end
  end

  describe "#psrepository_cmdlet_appropriate?" do
    it "returns true if the provider_name is 'PowerShellGet'" do
      resource.provider_name("PowerShellGet")
      expect(provider.psrepository_cmdlet_appropriate?).to eql(true)
    end

    it "returns false if the provider_name is something else" do
      resource.provider_name("NuGet")
      expect(provider.psrepository_cmdlet_appropriate?).to eql(false)
    end
  end

  describe "#package_source_exists?" do
    it "returns true if it exists" do
      allow(provider).to receive(:powershell_exec!).with("(Get-PackageSource -Name 'MyGallery' -ErrorAction SilentlyContinue).Name").and_return(double("powershell_exec!", result: "MyGallery\r\n"))
      resource.source_name("MyGallery")
      expect(provider.package_source_exists?).to eql(true)
    end

    it "returns false if it doesn't exist" do
      allow(provider).to receive(:powershell_exec!).with("(Get-PackageSource -Name 'MyGallery' -ErrorAction SilentlyContinue).Name").and_return(double("powershell_exec!", result: ""))
      resource.source_name("MyGallery")
      expect(provider.package_source_exists?).to eql(false)
    end
  end
end
