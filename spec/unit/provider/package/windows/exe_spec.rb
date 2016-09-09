#
# Author:: Matt Wrock <matt@mattwrock.com>
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
require "chef/provider/package/windows/exe"

unless Chef::Platform.windows?
  class Chef
    module ReservedNames::Win32
      class File
        def version_info
          nil
        end
      end
    end
  end
end

describe Chef::Provider::Package::Windows::Exe do
  let(:package_name) { "calculator" }
  let(:resource_source) { "calculator.exe" }
  let(:new_resource) do
    new_resource = Chef::Resource::WindowsPackage.new(package_name)
    new_resource.source(resource_source)
    new_resource
  end
  let(:uninstall_hash) do
    [{
      "DisplayVersion" => "outdated",
      "UninstallString" => File.join("uninst_dir", "uninst_file"),
    }]
  end
  let(:uninstall_entry) do
    entries = []
    uninstall_hash.each do |entry|
      entries.push(Chef::Provider::Package::Windows::RegistryUninstallEntry.new("hive", "key", entry))
    end
    entries
  end
  let(:provider) { Chef::Provider::Package::Windows::Exe.new(new_resource, :nsis, uninstall_entry) }

  before(:each) do
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
      expect(provider.installed_version).to eql(["outdated"])
    end

    context "no versions installed" do
      let(:uninstall_hash) { [] }

      it "returns the installed version" do
        expect(provider.installed_version).to eql(nil)
      end
    end
  end

  describe "package_version" do
    before { new_resource.version(nil) }

    context "source file does not exist" do
      before do
        allow(::File).to receive(:exist?).with(Chef::Util::PathHelper.canonical_path(resource_source, false)).and_return(false)
      end

      it "returns nil" do
        expect(provider.package_version).to eql(nil)
      end
    end

    it "returns the version attribute if given" do
      new_resource.version("v55555")
      expect(provider.package_version).to eql("v55555")
    end

    it "returns nil if no version given" do
      expect(provider.package_version).to eql(nil)
    end
  end

  describe "remove_package" do
    before do
      allow(::File).to receive(:exist?).and_return(false)
    end

    context "no version given and one package installed with unquoted uninstall string" do
      it "removes installed package and quotes uninstall string" do
        allow(::File).to receive(:exist?).with("uninst_dir/uninst_file").and_return(true)
        expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"uninst_dir\/uninst_file\" \/S \/NCRC & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
        provider.remove_package
      end
    end

    context "When timeout value is passed" do
      it "removes installed package and quotes uninstall string" do
        new_resource.timeout = 300
        allow(::File).to receive(:exist?).with("uninst_dir/uninst_file").and_return(true)
        expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"uninst_dir\/uninst_file\" \/S \/NCRC & exit %%%%ERRORLEVEL%%%%/, :timeout => 300, :returns => [0])
        provider.remove_package
      end
    end

    context "several packages installed with quoted uninstall strings" do
      let(:uninstall_hash) do
        [
          {
          "DisplayVersion" => "v1",
          "UninstallString" => "\"#{File.join("uninst_dir1", "uninst_file1")}\"",
          },
          {
          "DisplayVersion" => "v2",
          "UninstallString" => "\"#{File.join("uninst_dir2", "uninst_file2")}\"",
          },
        ]
      end

      context "version given and installed" do
        it "removes given version" do
          new_resource.version("v2")
          expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"uninst_dir2\/uninst_file2\" \/S \/NCRC & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
          provider.remove_package
        end
      end

      context "no version given" do
        it "removes both versions" do
          expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"uninst_dir1\/uninst_file1\" \/S \/NCRC & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
          expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"uninst_dir2\/uninst_file2\" \/S \/NCRC & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
          provider.remove_package
        end
      end
    end
  end

  context "installs nsis installer" do
    let(:provider) { Chef::Provider::Package::Windows::Exe.new(new_resource, :nsis, uninstall_entry) }

    it "calls installer with the correct flags" do
      expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"#{Regexp.quote(new_resource.source)}\" \/S \/NCRC  & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
      provider.install_package
    end
  end

  context "installs installshield installer" do
    let(:provider) { Chef::Provider::Package::Windows::Exe.new(new_resource, :installshield, uninstall_entry) }

    it "calls installer with the correct flags" do
      expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"#{Regexp.quote(new_resource.source)}\" \/s \/sms  & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
      provider.install_package
    end
  end

  context "installs inno installer" do
    let(:provider) { Chef::Provider::Package::Windows::Exe.new(new_resource, :inno, uninstall_entry) }

    it "calls installer with the correct flags" do
      expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"#{Regexp.quote(new_resource.source)}\" \/VERYSILENT \/SUPPRESSMSGBOXES \/NORESTART  & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
      provider.install_package
    end
  end

  context "installs wise installer" do
    let(:provider) { Chef::Provider::Package::Windows::Exe.new(new_resource, :wise, uninstall_entry) }

    it "calls installer with the correct flags" do
      expect(provider).to receive(:shell_out!).with(/start \"\" \/wait \"#{Regexp.quote(new_resource.source)}\" \/s  & exit %%%%ERRORLEVEL%%%%/, kind_of(Hash))
      provider.install_package
    end
  end
end
