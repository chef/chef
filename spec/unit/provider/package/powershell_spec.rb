#
# Author:: Dheeraj Dubey(<dheeraj.dubey@msystechnologies.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef/mixin/powershell_exec"

describe Chef::Provider::Package::Powershell, :windows_only, :windows_gte_10 do
  include Chef::Mixin::PowershellExec
  let(:timeout) { 900 }
  let(:source) { nil }

  let(:new_resource) { Chef::Resource::PowershellPackage.new("windows_test_pkg") }

  let(:provider) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Powershell.new(new_resource, run_context)
  end

  let(:package_xcertificate_installed) do
    double("powershell_exec", result: "2.1.0.0\r\n")
  end

  let(:package_xcertificate_installed_2_0_0_0) do
    double("powershell_exec", result: "2.0.0.0\r\n")
  end

  let(:package_xcertificate_available) do
    double("powershell_exec", result: "2.1.0.0\r\n")
  end

  let(:package_xcertificate_available_2_0_0_0) do
    double("powershell_exec", result: "2.0.0.0\r\n")
  end

  let(:package_xcertificate_not_installed) do
    double("powershell_exec", result: "")
  end

  let(:package_xcertificate_not_available) do
    double("powershell_exec", result: "")
  end

  let(:package_xnetworking_installed) do
    double("powershell_exec", result: "2.12.0.0\r\n")
  end

  let(:package_xnetworking_installed_2_11_0_0) do
    double("powershell_exec", result: "2.11.0.0\r\n")
  end

  let(:package_xnetworking_available) do
    double("powershell_exec", result: "2.12.0.0\r\n")
  end

  let(:package_xnetworking_available_2_11_0_0) do
    double("powershell_exec", result: "2.11.0.0\r\n")
  end

  let(:package_xnetworking_not_installed) do
    double("powershell_exec", result: "")
  end

  let(:package_xnetworking_not_available) do
    double("powershell_exec", result: "")
  end

  let(:package_7zip_available) do
    double("powershell_exec", result: "16.02\r\n")
  end

  let(:package_7zip_not_installed) do
    double("powershell_exec", result: "")
  end

  let(:powershell_installed_version) do
    double("powershell_exec", result: "5")
  end

  let(:tls_set_command) { "if ([Net.ServicePointManager]::SecurityProtocol -lt [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 };" }
  let(:generated_command) { "#{tls_set_command} ( Get-Package posh-git -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version" }
  let(:generated_get_cmdlet) { "#{tls_set_command} ( Get-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version" }
  let(:generated_get_cmdlet_with_version) { "#{tls_set_command} ( Get-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 ).Version" }
  let(:generated_find_cmdlet) { "#{tls_set_command} ( Find-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version" }
  let(:generated_find_cmdlet_with_version) { "#{tls_set_command} ( Find-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 ).Version" }
  let(:generated_find_cmdlet_with_source) { "#{tls_set_command} ( Find-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version" }
  let(:generated_find_cmdlet_with_source_and_version) { "#{tls_set_command} ( Find-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 -Source MyGallery ).Version" }
  let(:generated_install_cmdlet) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version" }
  let(:generated_install_cmdlet_with_version) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 ).Version" }
  let(:generated_install_cmdlet_with_source) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version" }
  let(:generated_install_cmdlet_with_options) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -AcceptLicense -Verbose ).Version" }
  let(:generated_install_cmdlet_with_version_and_options) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 -AcceptLicense -Verbose ).Version" }
  let(:generated_install_cmdlet_with_source_and_options) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery -AcceptLicense -Verbose ).Version" }
  let(:generated_install_cmdlet_with_source_and_version_and_options) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 -Source MyGallery -AcceptLicense -Verbose ).Version" }
  let(:generated_install_cmdlet_with_source_and_version) { "#{tls_set_command} ( Install-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 -Source MyGallery ).Version" }
  let(:generated_uninstall_cmdlet) { "#{tls_set_command} ( Uninstall-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version" }
  let(:generated_uninstall_cmdlet_with_version) { "#{tls_set_command} ( Uninstall-Package xNetworking -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 1.0.0.0 ).Version" }

  describe "#initialize" do
    it "should return the correct class" do
      expect(provider).to be_kind_of(Chef::Provider::Package::Powershell)
    end
  end

  describe "#candidate_version" do

    it "should set the candidate_version to the latest version when not pinning" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(["xNetworking"])
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.12.0.0"])
    end

    it "should use the candidate_version from the correct source" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(["xNetworking"])
      new_resource.version(nil)
      new_resource.source("MyGallery")
      expect(provider.candidate_version).to eql(["2.12.0.0"])
    end

    it "should set the candidate_version to the latest version when not pinning and package name is space separated" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package '7-Zip 16.02 (x64)' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_7zip_available)
      new_resource.package_name(["7-Zip 16.02 (x64)"])
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["16.02"])
    end

    it "should set the candidate_version to pinned version if available" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.0.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available_2_0_0_0)
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.0.0.0"])
      expect(provider.candidate_version).to eql(["2.0.0.0"])
    end

    it "should set the candidate_version to nil if there is no candidate" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      new_resource.package_name(["xCertificate"])
      expect(provider.candidate_version).to eql([nil])
    end

    it "should set the candidate_version correctly when there are two packages to install" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", "2.12.0.0"])
    end

    it "should set the candidate_version correctly when only the first is installable" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql(["2.1.0.0", nil])
    end

    it "should set the candidate_version correctly when only the last is installable" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, "2.12.0.0"])
    end

    it "should set the candidate_version correctly when neither are is installable and version is passed as nil array" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xNetworking xCertificate})
      new_resource.version([nil, nil])
      expect(provider.candidate_version).to eql([nil, nil])
    end

    it "should set the candidate_version correctly when neither are is installable and version is not passed" do
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      new_resource.package_name(%w{xNetworking xCertificate})
      new_resource.version(nil)
      expect(provider.candidate_version).to eql([nil, nil])
    end

  end

  describe "#build_powershell_package_command" do
    it "can build a valid command from a single string" do
      expect(provider.build_powershell_package_command("Get-Package posh-git")).to eql(generated_command)
    end

    it "can build a valid command from an array" do
      expect(provider.build_powershell_package_command(%w{Get-Package posh-git})).to eql(generated_command)
    end

    context "when source is nil" do
      it "builds get commands correctly" do
        expect(provider.build_powershell_package_command("Get-Package xNetworking")).to eql(generated_get_cmdlet)
      end

      it "builds get commands correctly when a version is passed" do
        expect(provider.build_powershell_package_command("Get-Package xNetworking", "1.0.0.0")).to eql(generated_get_cmdlet_with_version)
      end

      it "builds find commands correctly" do
        expect(provider.build_powershell_package_command("Find-Package xNetworking")).to eql(generated_find_cmdlet)
      end

      it "builds find commands correctly when a version is passed" do
        expect(provider.build_powershell_package_command("Find-Package xNetworking", "1.0.0.0")).to eql(generated_find_cmdlet_with_version)
      end

      it "builds install commands correctly" do
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet)
      end

      it "builds install commands correctly when a version is passed" do
        expect(provider.build_powershell_package_command("Install-Package xNetworking", "1.0.0.0")).to eql(generated_install_cmdlet_with_version)
      end

      it "builds install commands correctly when options are passed" do
        new_resource.options("-AcceptLicense -Verbose")
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet_with_options)
      end

      it "builds install commands correctly when duplicate options are passed" do
        new_resource.options("-WarningAction SilentlyContinue")
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet)
      end

      it "builds install commands correctly when a version and options are passed" do
        new_resource.options("-AcceptLicense -Verbose")
        expect(provider.build_powershell_package_command("Install-Package xNetworking", "1.0.0.0")).to eql(generated_install_cmdlet_with_version_and_options)
      end

      it "builds install commands correctly" do
        expect(provider.build_powershell_package_command("Uninstall-Package xNetworking")).to eql(generated_uninstall_cmdlet)
      end

      it "builds install commands correctly when a version is passed" do
        expect(provider.build_powershell_package_command("Uninstall-Package xNetworking", "1.0.0.0")).to eql(generated_uninstall_cmdlet_with_version)
      end
    end

    context "when source is set" do
      it "builds get commands correctly" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Get-Package xNetworking")).to eql(generated_get_cmdlet)
      end

      it "builds get commands correctly when a version is passed" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Get-Package xNetworking", "1.0.0.0")).to eql(generated_get_cmdlet_with_version)
      end

      it "builds find commands correctly" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Find-Package xNetworking")).to eql(generated_find_cmdlet_with_source)
      end

      it "builds find commands correctly when a version is passed" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Find-Package xNetworking", "1.0.0.0")).to eql(generated_find_cmdlet_with_source_and_version)
      end

      it "builds install commands correctly" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet_with_source)
      end

      it "builds install commands correctly when a version is passed" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Install-Package xNetworking", "1.0.0.0")).to eql(generated_install_cmdlet_with_source_and_version)
      end

      it "builds install commands correctly when options are passed" do
        new_resource.source("MyGallery")
        new_resource.options("-AcceptLicense -Verbose")
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet_with_source_and_options)
      end

      it "builds install commands correctly when duplicate options are passed" do
        new_resource.source("MyGallery")
        new_resource.options("-Force -ForceBootstrap")
        expect(provider.build_powershell_package_command("Install-Package xNetworking")).to eql(generated_install_cmdlet_with_source)
      end

      it "builds install commands correctly when a version and options are passed" do
        new_resource.source("MyGallery")
        new_resource.options("-AcceptLicense -Verbose")
        expect(provider.build_powershell_package_command("Install-Package xNetworking", "1.0.0.0")).to eql(generated_install_cmdlet_with_source_and_version_and_options)
      end

      it "builds install commands correctly" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Uninstall-Package xNetworking")).to eql(generated_uninstall_cmdlet)
      end

      it "builds install commands correctly when a version is passed" do
        new_resource.source("MyGallery")
        expect(provider.build_powershell_package_command("Uninstall-Package xNetworking", "1.0.0.0")).to eql(generated_uninstall_cmdlet_with_version)
      end
    end
  end

  describe "#action_install" do
    it "should install a single package" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install a single package from a custom source" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      new_resource.source("MyGallery")
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 -Source MyGallery ).Version", { timeout: new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install a package without the publisher check" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      new_resource.skip_publisher_check(true)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -SkipPublisherCheck ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 -SkipPublisherCheck ).Version", { timeout: new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install a single package when package name has space in between" do
      provider.load_current_resource
      new_resource.package_name(["7-Zip 16.02 (x64)"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package '7-Zip 16.02 (x64)' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_7zip_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package '7-Zip 16.02 (x64)' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_7zip_not_installed)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package '7-Zip 16.02 (x64)' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 16.02 ).Version", { timeout: new_resource.timeout })
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
        allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
        allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
        allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
        expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
        provider.run_action(:install)
        expect(new_resource).to be_updated_by_last_action
      end
    end

    it "should not install packages that are up-to-date" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "should not install packages that are up-to-date" do
      new_resource.package_name(["xNetworking"])
      new_resource.version(["2.11.0.0"])
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.11.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.11.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available_2_11_0_0)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
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
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.11.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available_2_11_0_0)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.11.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.11.0.0 ).Version", { timeout: new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should split up commands when given two packages, one with a version pin" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(["2.1.0.0", nil])
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.12.0.0 ).Version", { timeout: new_resource.timeout })

      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should do multipackage installs when given two packages without constraints" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.12.0.0 ).Version", { timeout: new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should do multipackage installs from a custom source when given two packages without constraints" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      new_resource.source("MyGallery")
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -Source MyGallery ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 -Source MyGallery ).Version", { timeout: new_resource.timeout })
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.12.0.0 -Source MyGallery ).Version", { timeout: new_resource.timeout })
      provider.load_current_resource
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should install a package using provided options" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      new_resource.options(%w{-AcceptLicense -Verbose})
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Install-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 -AcceptLicense -Verbose ).Version", { timeout: new_resource.timeout })
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "#action_remove" do
    it "does nothing when the package is already removed" do
      provider.load_current_resource
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "does not pass the source parameter to get or uninstall cmdlets" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      new_resource.source("MyGallery")
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 -Source MyGallery).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Uninstall-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "does nothing when all the packages are already removed" do
      new_resource.package_name(%w{xCertificate xNetworking})
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xNetworking' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xnetworking_not_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "removes a package when version is specified" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(["2.1.0.0"])
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Uninstall-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -RequiredVersion 2.1.0.0 ).Version", { timeout: new_resource.timeout })
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "removes a package when version is not specified" do
      new_resource.package_name(["xCertificate"])
      new_resource.version(nil)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Uninstall-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end

    it "should remove a package using provided options" do
      new_resource.package_name(["xCertificate"])
      new_resource.options(%w{-AllVersions})
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Find-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Get-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_available)
      allow(provider).to receive(:powershell_exec).with("$PSVersionTable.PSVersion.Major").and_return(powershell_installed_version)
      provider.load_current_resource
      expect(provider).to receive(:powershell_exec).with("#{tls_set_command} ( Uninstall-Package 'xCertificate' -Force -ForceBootstrap -WarningAction SilentlyContinue -AllVersions ).Version", { timeout: new_resource.timeout }).and_return(package_xcertificate_not_available)
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end
  end
end
