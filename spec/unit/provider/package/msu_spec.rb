#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
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

describe Chef::Provider::Package::Msu, :windows_only do
  let(:timeout) {}

  let(:new_resource) { Chef::Resource::MsuPackage.new("windows_test_pkg") }

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Msu.new(new_resource, run_context)
  end

  let(:installed_package_list_stdout) do
    <<-EOF
Packages listing:
Package Identity : Package_for_KB2999486~31bf3856ad364e35~amd64~~6.1.9768.0
Package Identity : Package_for_KB2994825~31bf3856ad364e35~amd64~~6.1.7601.0
    EOF
  end

  let(:package_version_stdout) do
    <<-EOF
Package information:
Package Identity : Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0
State : Installed
Dependency : Language Pack
The operation completed successfully
    EOF
  end

  let(:get_package_info_stdout) do
    <<-EOF
Deployment Image Servicing and Management tool
Version: 6.1.7600.16385

Image Version: 6.1.7600.16385

Package information:
Package Identity : Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0
Applicable : Yes
Copyright : Microsoft Corporation
Company : Microsoft Corporation
State : Installed
Dependency : Language Pack
The operation completed successfully
    EOF
  end

  def allow_get_packages
    get_packages_stdout = <<-EOF
Deployment Image Servicing and Management tool
Version: 6.1.7600.16385

Image Version: 6.1.7600.16385

Packages listing:

Package Identity : Package_for_KB2999486~31bf3856ad364e35~amd64~~6.1.9768.0
State : Installed
Release Type : Language Pack
Install Time : 2/11/2015 11:33 PM

Package Identity : Package_for_KB2994825~31bf3856ad364e35~amd64~~6.1.7601.0
State : Installed
Release Type : Language Pack
Install Time : 2/11/2015 11:33 PM

Package Identity : Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0
State : Installed
Release Type : Feature Pack
Install Time : 11/21/2010 3:40 AM

The operation completed successfully.
    EOF
    get_packages_obj = double(stdout: get_packages_stdout)
    allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-Packages").and_return(get_packages_obj)
  end

  before do
    allow(Dir).to receive(:mktmpdir)
    allow(provider).to receive(:cleanup_after_converge)
  end

  describe "#initialize" do
    it "returns the correct class" do
      expect(provider).to be_kind_of(Chef::Provider::Package::Msu)
    end
  end

  describe "#load_current_resource" do
    before do
      new_resource.source = "C:\\Temp\\Test6.1-KB2664825-v3-x64.msu"
      cab_file = "c:\\temp\\test6.1-kb2664825-v3-x64.cab"
      allow(provider).to receive(:extract_msu_contents)
      allow(provider).to receive(:read_cab_files_from_xml).and_return([cab_file])
      installed_package_list_obj = double(stdout: installed_package_list_stdout)
      allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-Packages").and_return(installed_package_list_obj)
      package_version_obj = double(stdout: package_version_stdout)
      allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{cab_file}\"").and_return(package_version_obj)
    end

    it "returns a current_resource" do
      expect(provider.load_current_resource).to be_kind_of(Chef::Resource::MsuPackage)
    end

    it "sets the current_resource.version to nil when the package is not installed" do
      provider.load_current_resource
      expect(provider.current_resource.version).to eql([nil])
    end

    it "calls download_source_file method if source is a URL" do
      new_resource.source = "https://www.something.com/Test6.1-KB2664825-v3-x64.msu"
      expect(provider).to receive(:download_source_file)
      provider.load_current_resource
    end
  end

  describe "#source_resource" do
    before do
      new_resource.source = "C:\\Temp\\Test6.1-KB2664825-v3-x64.msu"
      new_resource.cookbook_name = "Msu_package"
    end

    it "sets the desired parameters of downloades msu file" do
      allow(provider).to receive(:default_download_cache_path).and_return("C:\\chef\\cache\\package")
      source_resource = provider.source_resource
      expect(source_resource.path).to be == "C:\\chef\\cache\\package"
      expect(source_resource.name).to be == "windows_test_pkg"
      expect(source_resource.source).to be == [new_resource.source]
      expect(source_resource.cookbook_name).to be == "Msu_package"
      expect(source_resource.checksum).to be nil
    end
  end

  describe "#default_download_cache_path" do
    before do
      new_resource.source = "https://www.something.com/Test6.1-KB2664825-v3-x64.msu"
    end

    it "returns a clean cache path where the msu file is downloaded" do
      allow(Chef::FileCache).to receive(:create_cache_path).and_return("C:\\chef\\abc\\package")
      path = provider.default_download_cache_path
      expect(path).to be == "C:\\chef\\abc\\package\\Test6.1-KB2664825-v3-x64.msu"
    end
  end

  describe "action specs" do
    before do
      new_resource.source = "C:\\Temp\\Test6.1-KB2664825-v3-x64.msu"
      cab_file = "c:\\temp\\test6.1-kb2664825-v3-x64.cab"
      allow(provider).to receive(:extract_msu_contents)
      allow(provider).to receive(:read_cab_files_from_xml).and_return([cab_file])
      installed_package_list_obj = double(stdout: installed_package_list_stdout)
      allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-Packages").and_return(installed_package_list_obj)
      package_version_obj = double(stdout: package_version_stdout)
      allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{cab_file}\"").and_return(package_version_obj)
    end

    describe "#action_install" do
      it "installs package if not already installed" do
        provider.load_current_resource
        expect(provider.current_resource.version).to eql([nil])
        expect(provider).to receive(:install_package)
        provider.run_action(:install)
        expect(new_resource).to be_updated_by_last_action
      end

      it "does not install package if already installed" do
        get_package_info_obj = double(stdout: get_package_info_stdout)
        allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{new_resource.source}\"").and_return(get_package_info_obj)
        allow_get_packages
        allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackageName:\"Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0\"").and_return(get_package_info_obj)
        provider.load_current_resource
        expect(provider.current_resource.version).to eql(["6.1.3.0"])
        expect(provider).not_to receive(:install_package)
        provider.run_action(:install)
        expect(new_resource).not_to be_updated_by_last_action
      end
    end

    describe "#action_remove" do
      it "does nothing when the package is not present" do
        provider.load_current_resource
        expect(provider).not_to receive(:remove_package)
        provider.run_action(:remove)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "removes packages if package is installed" do
        get_package_info_obj = double(stdout: get_package_info_stdout)
        allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{new_resource.source}\"").and_return(get_package_info_obj)
        allow_get_packages
        allow_any_instance_of(Chef::Provider::Package::Cab).to receive(:dism_command).with("/Get-PackageInfo /PackageName:\"Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0\"").and_return(get_package_info_obj)
        provider.load_current_resource
        expect(provider.current_resource.version).to eql(["6.1.3.0"])
        expect(provider).to receive(:remove_package)
        provider.run_action(:remove)
        expect(new_resource).to be_updated_by_last_action
      end
    end

    context "Invalid package source" do
      def package_version_stdout
        package_version_stdout = <<-EOF

  Deployment Image Servicing and Management tool
  Version: 6.1.7600.16385

  Image Version: 6.1.7600.16385

  An error occurred trying to open - c:\\temp\\test6.1-KB2664825-v3-x64.cab Error: 0x80070003
  Error: 3
  The system cannot find the path specified.
  The DISM log file can be found at C:\\Windows\\Logs\\DISM\\dism.log.
        EOF
      end

      it "raises error for invalid source path or file" do
        expect { provider.load_current_resource }.to raise_error(Chef::Exceptions::Package, "DISM: The system cannot find the path or file specified.")
      end
    end
  end

  describe "#extract_msu_contents" do
    it "extracts the msu contents by using mixlib shellout" do
      expect(provider).to receive(:shell_out_with_timeout!).with("#{ENV['SYSTEMROOT']}\\system32\\expand.exe -f:* msu_file destination")
      provider.extract_msu_contents("msu_file", "destination")
    end
  end

  describe "#read_cab_files_from_xml" do
    it "raises error if the xml file is not present" do
      allow(Dir).to receive(:glob).and_return([])
      expect { provider.read_cab_files_from_xml("msu_dir") }.to raise_error(Chef::Exceptions::Package)
    end

    it "parses xml file with single cab file" do
      xml_file = File.join(CHEF_SPEC_DATA, "sample_msu1.xml")
      allow(Dir).to receive(:glob).and_return([xml_file])
      cab_files = provider.read_cab_files_from_xml("msu_dir")
      expect(cab_files).to eql(["msu_dir/IE10-Windows6.1-KB2859903-x86.CAB"])
    end

# We couldn't find any msu file with multiple cab files in it.
# So we are not 100% sure about the structure of XML file in this case
# The specs below cover 2 possible XML formats
    context "handles different xml formats for multiple cab files in the msu package" do
      it "parses xml file with multiple <package> tags" do
        xml_file = File.join(CHEF_SPEC_DATA, "sample_msu2.xml")
        allow(Dir).to receive(:glob).and_return([xml_file])
        cab_files = provider.read_cab_files_from_xml("msu_dir")
        expect(cab_files).to eql(["msu_dir/IE10-Windows6.1-KB2859903-x86.CAB", "msu_dir/abc.CAB"])
      end

      it "parses xml file with multiple <servicing> tags" do
        xml_file = File.join(CHEF_SPEC_DATA, "sample_msu3.xml")
        allow(Dir).to receive(:glob).and_return([xml_file])
        cab_files = provider.read_cab_files_from_xml("msu_dir")
        expect(cab_files).to eql(["msu_dir/IE10-Windows6.1-KB2859903-x86.CAB", "msu_dir/abc.CAB"])
      end
    end
  end
end
