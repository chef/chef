#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
require "chef/provider/package/windows/msi"

describe Chef::Provider::Package::Windows::MSI do
  let(:node) { double("Chef::Node") }
  let(:events) { double("Chef::Events").as_null_object } # mock all the methods
  let(:run_context) { double("Chef::RunContext", :node => node, :events => events) }
  let(:package_name) { "calculator" }
  let(:resource_source) { "calculator.msi" }
  let(:resource_version) { nil }
  let(:new_resource) do
    new_resource = Chef::Resource::WindowsPackage.new(package_name)
    new_resource.source(resource_source)
    new_resource.version(resource_version)
    new_resource
  end
  let(:uninstall_hash) do
    [{
      "DisplayVersion" => "outdated",
      "UninstallString" => "MsiExec.exe /X{guid}",
    }]
  end
  let(:uninstall_entry) do
    entries = []
    uninstall_hash.each do |entry|
      entries.push(Chef::Provider::Package::Windows::RegistryUninstallEntry.new("hive", "key", entry))
    end
    entries
  end
  let(:provider) { Chef::Provider::Package::Windows::MSI.new(new_resource, uninstall_entry) }
  before do
    allow(::File).to receive(:exist?).with(Chef::Util::PathHelper.canonical_path(resource_source, false)).and_return(true)
  end

  it "responds to shell_out!" do
    expect(provider).to respond_to(:shell_out!)
  end

  describe "expand_options" do
    it "returns an empty string if passed no options" do
      expect(provider.expand_options(nil)).to eql ""
    end

    it "returns a string with a leading space if passed options" do
      expect(provider.expand_options("--train nope --town no_way")).to eql(" --train nope --town no_way")
    end
  end

  describe "installed_version" do
    it "returns the installed version" do
      allow(provider).to receive(:get_product_property).and_return("{23170F69-40C1-2702-0920-000001000000}")
      allow(provider).to receive(:get_installed_version).with("{23170F69-40C1-2702-0920-000001000000}").and_return("3.14159.1337.42")
      expect(provider.installed_version).to eql("3.14159.1337.42")
    end

    it "returns the installed version in the registry when install file not present" do
      allow(::File).to receive(:exist?).with(Chef::Util::PathHelper.canonical_path(resource_source, false)).and_return(false)
      expect(provider.installed_version).to eql(["outdated"])
    end
  end

  describe "package_version" do
    it "returns the version of a package" do
      allow(provider).to receive(:get_product_property).with(/calculator.msi$/, "ProductVersion").and_return(42)
      expect(provider.package_version).to eql(42)
    end

    context "version is explicitly provided" do
      let(:resource_version) { "given_version" }

      it "returns the given version" do
        expect(provider.package_version).to eql("given_version")
      end
    end

    context "no source or version is given" do
      before do
        allow(::File).to receive(:exist?).with(Chef::Util::PathHelper.canonical_path(resource_source, false)).and_return(false)
      end

      it "returns nil" do
        expect(provider.package_version).to eql(nil)
      end
    end
  end

  describe "install_package" do
    it "calls msiexec /qn /i" do
      expect(provider).to receive(:shell_out!).with(/msiexec \/qn \/i \"#{Regexp.quote(new_resource.source)}\"/, kind_of(Hash))
      provider.install_package
    end
  end

  describe "remove_package" do
    it "calls msiexec /qn /x" do
      expect(provider).to receive(:shell_out!).with(/msiexec \/qn \/x \"#{Regexp.quote(new_resource.source)}\"/, kind_of(Hash))
      provider.remove_package
    end

    context "no source is provided" do
      before do
        allow(::File).to receive(:exist?).with(Chef::Util::PathHelper.canonical_path(resource_source, false)).and_return(false)
      end

      it "removes installed package" do
        expect(provider).to receive(:shell_out!).with(/msiexec \/x {guid} \/q/, kind_of(Hash))
        provider.remove_package
      end

      context "there are multiple installs" do
        let(:uninstall_hash) do
          [
            {
              "DisplayVersion" => "outdated",
              "UninstallString" => "MsiExec.exe /X{guid}",
            },
            {
              "DisplayVersion" => "really_outdated",
              "UninstallString" => "MsiExec.exe /X{guid2}",
            },
          ]
        end

        it "removes both installed package" do
          expect(provider).to receive(:shell_out!).with(/msiexec \/x {guid} \/q/, kind_of(Hash))
          expect(provider).to receive(:shell_out!).with(/msiexec \/x {guid2} \/q/, kind_of(Hash))
          provider.remove_package
        end
      end

      context "custom options includes /Q" do
        before { new_resource.options("/Q") }

        it "does not duplicate quiet switch" do
          expect(provider).to receive(:shell_out!).with(/msiexec \/x {guid} \/Q/, kind_of(Hash))
          provider.remove_package
        end
      end

      context "custom options includes /qn" do
        before { new_resource.options("/qn") }

        it "does not duplicate quiet switch" do
          expect(provider).to receive(:shell_out!).with(/msiexec \/x {guid} \/qn/, kind_of(Hash))
          provider.remove_package
        end
      end
    end
  end
end
