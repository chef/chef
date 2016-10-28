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

  let(:installed_package_stdout) do
    <<-EOF
"\r\nName                           Version          Source           Summary                                               \r\n----                           -------          ------           -------                                               \r\nxCertificate                   2.1.0.0          PSGallery        This module includes DSC resources that simplify administration of certificates on a Windows Server"
    EOF
  end

  let(:package_version_stdout) do
    <<-EOF
"\r\nName                           Version          Source           Summary                                               \r\n----                           -------          ------           -------                                               \r\nxCertificate                   2.1.0.0          https://www.powershellgallery... PowerShellGet"
    EOF
  end

  let(:installed_package_stdout_xnetworking) do
    <<-EOF
"\r\nName                           Version          Source           Summary                                               \r\n----                           -------          ------           -------                                               \r\nxNetworking                   2.12.0.0          PSGallery        Module with DSC resources for Networking Area"
    EOF
  end

  let(:package_version_stdout_xnetworking) do
    <<-EOF
"\r\nName                           Version          Source           Summary                                               \r\n----                           -------          ------           -------                                               \r\nxNetworking                   2.12.0.0          https://www.powershellgallery... PowerShellGet"
    EOF
  end

  describe "#initialize" do
    it "should return the correct class" do
      expect(provider).to be_kind_of(Chef::Provider::Package::Powershell)
    end
  end

  describe "#candidate_version" do

    it "should set the candidate_version to the latest version when not pinning" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0"])
    end

    it "should set the candidate_version to pinned version if available" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double)
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      expect(provider.candidate_version).to eql(["2.1.0.0"])
    end

    it "should set the candidate_version to nil if there is no candidate" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return("")
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      new_resource.package_name(["xCertificate"])
      expect(provider.candidate_version).to eql([nil])
    end

    it "should set the candidate_version correctly when there are two packages to install" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double1)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", "2.12.0.0"])
    end

    it "should set the candidate_version correctly when only the first is installable" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double1)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", nil])
    end

    it "should set the candidate_version correctly when only the last is installable" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return("")
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double1)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, "2.12.0.0"])
    end

    it "should set the candidate_version correctly when neither are is installable" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return("")
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double1)
      new_resource.package_name(%w{xNetworking xCertificate})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, nil])
    end
  end

  describe "#action_install" do
    it "should install a single package" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      expect(provider).to receive(:powershell_out).with("Install-Package xCertificate -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    context "when changing the timeout to 3600" do
      let(:timeout) { 3600 }
      it "sets the timeout on shell_out commands" do
        my_double = double("powershellout_double")
        allow(my_double).to receive(:stdout).and_return(package_version_stdout)
        my_double1 = double("powershellout_double")
        allow(my_double1).to receive(:stdout).and_return("")
        my_double2 = double("powershellout_double")
        allow(my_double2).to receive(:stdout).and_return("5")
        new_resource.timeout(timeout)
        provider.load_current_resource
        new_resource.package_name(["xCertificate"])
        new_resource.version(nil)
        allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
        allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
        allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
        expect(provider).to receive(:powershell_out).with("Install-Package xCertificate -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
        provider.run_action(:install)
        expect(new_resource).to be_updated_by_last_action
      end
    end

    it "should not install packages that are up-to-date" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return(installed_package_stdout)
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")

      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)

      provider.load_current_resource
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should handle complicated cases when the name/version array is pruned" do
      # implicitly test that we correctly pick up new_resource.version[1] instead of
      # new_version.resource[0]
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      my_double3 = double("powershellout_double")
      allow(my_double3).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      my_double4 = double("powershellout_double")
      allow(my_double4).to receive(:stdout).and_return("")

      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version([nil, "2.12.0.0"])
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout }).and_return(my_double3)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xNetworking -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout }).and_return(my_double4)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      expect(provider).to receive(:powershell_out).with("Install-Package xCertificate -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package xNetworking -Force -ForceBootstrap -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should split up commands when given two packages, one with a version pin" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      my_double3 = double("powershellout_double")
      allow(my_double3).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      my_double4 = double("powershellout_double")
      allow(my_double4).to receive(:stdout).and_return("")
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(["2.1.0.0", nil])
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double3)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xNetworking", { :timeout => new_resource.timeout }).and_return(my_double4)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      expect(provider).to receive(:powershell_out).with("Install-Package xCertificate -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package xNetworking -Force -ForceBootstrap -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should do multipackage installs when given two packages without constraints" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      my_double3 = double("powershellout_double")
      allow(my_double3).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      my_double4 = double("powershellout_double")
      allow(my_double4).to receive(:stdout).and_return("")
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double3)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xNetworking", { :timeout => new_resource.timeout }).and_return(my_double4)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      expect(provider).to receive(:powershell_out).with("Install-Package xCertificate -Force -ForceBootstrap -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      expect(provider).to receive(:powershell_out).with("Install-Package xNetworking -Force -ForceBootstrap -RequiredVersion 2.12.0.0", { :timeout => new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "#action_remove" do
    it "does nothing when the package is already removed" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "does nothing when all the packages are already removed" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return("")
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      my_double3 = double("powershellout_double")
      allow(my_double3).to receive(:stdout).and_return(package_version_stdout_xnetworking)
      my_double4 = double("powershellout_double")
      allow(my_double4).to receive(:stdout).and_return("")
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("Find-Package xNetworking", { :timeout => new_resource.timeout }).and_return(my_double3)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xNetworking", { :timeout => new_resource.timeout }).and_return(my_double4)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)
      provider.load_current_resource
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "removes a package when version is specified" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return(installed_package_stdout)
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")

      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)

      provider.load_current_resource
      expect(provider).to receive(:powershell_out).with("Uninstall-Package xCertificate -Force -RequiredVersion 2.1.0.0", { :timeout => new_resource.timeout })
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "removes a package when version is not specified" do
      my_double = double("powershellout_double")
      allow(my_double).to receive(:stdout).and_return(package_version_stdout)
      my_double1 = double("powershellout_double")
      allow(my_double1).to receive(:stdout).and_return(installed_package_stdout)
      my_double2 = double("powershellout_double")
      allow(my_double2).to receive(:stdout).and_return("5")
      my_double3 = double("powershellout_double")
      allow(my_double3).to receive(:stdout).and_return("")

      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_out).with("Find-Package xCertificate", { :timeout => new_resource.timeout }).and_return(my_double)
      allow(provider).to receive(:powershell_out).with("Get-Package -Name xCertificate", { :timeout => new_resource.timeout }).and_return(my_double1)
      allow(provider).to receive(:powershell_out).with("$PSVersionTable.PSVersion.Major").and_return(my_double2)

      provider.load_current_resource
      expect(provider).to receive(:powershell_out).with("Uninstall-Package xCertificate -Force", { :timeout => new_resource.timeout }).and_return(my_double3)
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end
  end
end
