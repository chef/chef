#
# Author:: Dheeraj Dubey(<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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
require "chef/mixin/powershell_out"

describe Chef::Provider::Package::Powershell do
  include Chef::Mixin::PowershellOut
  let(:timeout) { 900 }

  let(:new_resource) { Chef::Resource::PowershellPackage.new("windows_test_pkg") }

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Powershell.new(new_resource, run_context)
  end

  let(:package_xcertificate_installed) do
    double("powershell_out", :stdout => "2.1.0.0\r\n")
  end

  let(:package_xcertificate_installed_2_0_0_0) do
    double("powershell_out", :stdout => "2.0.0.0\r\n")
  end

  let(:package_xcertificate_available) do
    double("powershell_out", :stdout => "2.1.0.0\r\n")
  end

  let(:package_xcertificate_available_2_0_0_0) do
    double("powershell_out", :stdout => "2.0.0.0\r\n")
  end

  let(:package_xcertificate_not_installed) do
    double("powershell_out", :stdout => "")
  end

  let(:package_xcertificate_not_available) do
    double("powershell_out", :stdout => "")
  end

  let(:package_xnetworking_installed) do
    double("powershell_out", :stdout => "2.12.0.0\r\n")
  end

  let(:package_xnetworking_installed_2_11_0_0) do
    double("powershell_out", :stdout => "2.11.0.0\r\n")
  end

  let(:package_xnetworking_available) do
    double("powershell_out", :stdout => "2.12.0.0\r\n")
  end

  let(:package_xnetworking_available_2_11_0_0) do
    double("powershell_out", :stdout => "2.11.0.0\r\n")
  end

  let(:package_xnetworking_not_installed) do
    double("powershell_out", :stdout => "")
  end

  let(:package_xnetworking_not_available) do
    double("powershell_out", :stdout => "")
  end

  let(:package_7zip_available) do
    double("powershell_out", :stdout => "16.02\r\n")
  end

  let(:package_7zip_not_installed) do
    double("powershell_out", :stdout => "")
  end

  let(:powershell_installed_version) do
    double("powershell_out", :stdout => "5")
  end

  describe "#initialize" do
    it "should return the correct class" do
      expect(provider).to be_kind_of(Chef::Provider::Package::Powershell)
    end
  end

  describe "#candidate_version" do

    it "should set the candidate_version to the latest version when not pinning" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(["xNetworking"])
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.12.0.0"])
    end

    it "should set the candidate_version to the latest version when not pinning and package name is space seperated" do
      allow(provider).to receive(:powershell_out).with("(Find-Package '7-Zip 16.02 (x64)' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_7zip_available)
      new_resource.package_name(["7-Zip 16.02 (x64)"])
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["16.02"])
    end

    it "should set the candidate_version to pinned version if available" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -RequiredVersion 2.0.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available_2_0_0_0)
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.0.0.0"])
      expect(provider.candidate_version).to eql(["2.0.0.0"])
    end

    it "should set the candidate_version to nil if there is no candidate" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      new_resource.package_name(["xCertificate"])
      expect(provider.candidate_version).to eql([nil])
    end

    it "should set the candidate_version correctly when there are two packages to install" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", "2.12.0.0"])
    end

    it "should set the candidate_version correctly when only the first is installable" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", nil])
    end

    it "should set the candidate_version correctly when only the last is installable" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, "2.12.0.0"])
    end

    it "should set the candidate_version correctly when neither are is installable and version is passed as nil array" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xNetworking xCertificate})
      new_resource.version([nil, nil])
      expect(provider.candidate_version).to eql([nil, nil])
    end

    it "should set the candidate_version correctly when neither are is installable and version is not passed" do
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xNetworking xCertificate})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, nil])
    end

  end

  describe "#action_install" do
    it "should install a single package" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_out).with("Install-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install a single package when package name has space in between" do
      provider.load_current_resource
      new_resource.package_name(["7-Zip 16.02 (x64)"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package '7-Zip 16.02 (x64)' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_7zip_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name '7-Zip 16.02 (x64)' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_7zip_not_installed)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_out).with("Install-Package '7-Zip 16.02 (x64)' -Force -ForceBootstrap -RequiredVersion 16.02", { :timeout => new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    context "when changing the timeout to 3600" do
      let(:timeout) { 3600 }
      it "sets the timeout on shell_out commands" do
        new_resource.timeout(timeout)
        provider.load_current_resource
        new_resource.package_name(["xCertificate"])
        new_resource.version(nil)
        allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
        allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
        allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
        expect(provider).to receive(:powershell_out).with("Install-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
        provider.run_action(:install)
        expect(new_resource).to be_updated_by_last_action
      end
    end

    it "should not install packages that are up-to-date" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not install packages that are up-to-date" do
      new_resource.package_name(["xNetworking"])
      new_resource.version(["2.11.0.0"])
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -RequiredVersion 2.11.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xNetworking' -RequiredVersion 2.11.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available_2_11_0_0)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should handle complicated cases when the name/version array is pruned" do
      # implicitly test that we correctly pick up new_resource.version[1] instead of
      # new_version.resource[0]
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version([nil, "2.11.0.0"])
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -RequiredVersion 2.11.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available_2_11_0_0)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xNetworking' -RequiredVersion 2.11.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_out).with("Install-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package 'xNetworking' -Force -ForceBootstrap -RequiredVersion 2.11.0.0", { :timeout => new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should split up commands when given two packages, one with a version pin" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(["2.1.0.0", nil])
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_out).with("Install-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package 'xNetworking' -Force -ForceBootstrap -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout })

      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should do multipackage installs when given two packages without constraints" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_out).with("Install-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package 'xNetworking' -Force -ForceBootstrap -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "#action_remove" do
    it "does nothing when the package is already removed" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "does nothing when all the packages are already removed" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xNetworking' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "removes a package when version is specified" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -RequiredVersion 2.1.0.0 -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_out).with("Uninstall-Package 'xCertificate' -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "removes a package when version is not specified" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("(Find-Package 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("(Get-Package -Name 'xCertificate' -ForceBootstrap -Force | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_out).with("(Uninstall-Package 'xCertificate' -Force -ForceBootstrap | select version | Format-Table -HideTableHeaders | Out-String).Trim()", { :timeout => new_resource.timeout }).and_return(package_xcertificate_not_available)
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end
  end
end
