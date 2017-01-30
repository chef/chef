#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@msystechnologies.com>)
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

describe Chef::Provider::Package::Cab do
  let(:timeout) {}

  let(:new_resource) { Chef::Resource::CabPackage.new("windows_test_pkg") }

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Cab.new(new_resource, run_context)
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

  before do
    new_resource.source = File.join("#{ENV['TEMP']}", "test6.1-kb2664825-v3-x64.cab")
    installed_package_list_obj = double(stdout: installed_package_list_stdout)
    allow(provider).to receive(:dism_command).with("/Get-Packages").and_return(installed_package_list_obj)
    package_version_obj = double(stdout: package_version_stdout)
    allow(provider).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{new_resource.source}\"").and_return(package_version_obj)
  end

  def allow_package_info(package_path = nil, package_name = nil)
    get_package_info_stdout = <<-EOF
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
    get_package_info_obj = double(stdout: get_package_info_stdout)
    if package_path
      allow(provider).to receive(:dism_command).with("/Get-PackageInfo /PackagePath:\"#{package_path}\"").and_return(get_package_info_obj)
    else
      allow(provider).to receive(:dism_command).with("/Get-PackageInfo /PackageName:\"#{package_name}\"").and_return(get_package_info_obj)
    end
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
    allow(provider).to receive(:dism_command).with("/Get-Packages").and_return(get_packages_obj)
  end

  describe "#load_current_resource" do
    it "returns a current_resource" do
      expect(provider.load_current_resource).to be_kind_of(Chef::Resource::CabPackage)
    end

    it "sets the current_resource.version to nil when the package is not installed" do
      provider.load_current_resource
      expect(provider.current_resource.version).to eql(nil)
    end

    it "sets the new resource package version" do
      provider.load_current_resource
      expect(provider.new_resource.version).to eql("6.1.3.0")
    end
  end

  describe "#source_resource" do
    before do
      new_resource.source = "https://www.something.com/Test6.1-KB2664825-v3-x64.cab"
      new_resource.cookbook_name = "cab_package"
    end

    it "sets the desired parameters of downloades cab file" do
      allow(provider).to receive(:default_download_cache_path).and_return("C:\\chef\\cache\\package")
      source_resource = provider.source_resource
      expect(source_resource.path).to be == "C:\\chef\\cache\\package"
      expect(source_resource.name).to be == "windows_test_pkg"
      expect(source_resource.source).to be == [new_resource.source]
      expect(source_resource.cookbook_name).to be == "cab_package"
    end
  end

  describe "#default_download_cache_path" do
    before do
      new_resource.source = "https://www.something.com/Test6.1-KB2664825-v3-x64.cab"
    end

    it "returns a clean cache path where the cab file is downloaded" do
      allow(Chef::FileCache).to receive(:create_cache_path).and_return(ENV["TEMP"])
      path = provider.default_download_cache_path
      if windows?
        expect(path).to be == File.join("#{ENV['TEMP']}", "\\", "Test6.1-KB2664825-v3-x64.cab")
      else
        expect(path).to be == File.join("#{ENV['TEMP']}", "Test6.1-KB2664825-v3-x64.cab")
      end
    end
  end

  describe "#cab_file_source" do
    context "when local file path is set" do
      it "returns local cab file source path" do
        new_resource.source = File.join("#{ENV['TEMP']}", "test6.1-kb2664825-v3-x64.cab")
        path = provider.cab_file_source
        if windows?
          expect(path).to be == File.join("#{ENV['TEMP'].downcase}", "\\", "test6.1-kb2664825-v3-x64.cab")
        else
          expect(path).to be == File.join("#{ENV['TEMP']}", "test6.1-kb2664825-v3-x64.cab")
        end
      end
    end
    context "when url is set" do
      it "calls download_source_file method" do
        new_resource.source = "https://www.something.com/test6.1-kb2664825-v3-x64.cab"
        if windows?
          expect(provider).to receive(:download_source_file).and_return(File.join("#{ENV['TEMP'].downcase}", "\\", "test6.1-kb2664825-v3-x64.cab"))
        else
          expect(provider).to receive(:download_source_file).and_return(File.join("#{ENV['TEMP']}", "test6.1-kb2664825-v3-x64.cab"))
        end
        provider.cab_file_source
      end
    end
  end

  describe "#initialize" do
    it "returns the correct class" do
      expect(provider).to be_kind_of(Chef::Provider::Package::Cab)
    end
  end

  describe "#package_version" do
    it "returns the new package version" do
      allow_package_info(new_resource.source, nil)
      expect(provider.package_version).to eql("6.1.3.0")
    end
  end

  describe "#installed_version" do
    it "returns the current installed version of package" do
      allow_package_info(new_resource.source, nil)
      allow_get_packages
      allow_package_info(nil, "Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0")
      expect(provider.installed_version).to eql("6.1.3.0")
    end
  end

  describe "#action_remove" do
    it "does nothing when the package is already removed" do
      provider.load_current_resource
      expect(provider).not_to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "removes packages if package is installed" do
      allow_package_info(new_resource.source, nil)
      allow_get_packages
      allow_package_info(nil, "Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0")
      provider.load_current_resource
      expect(provider.installed_version).not_to eql(nil)
      expect(provider).to receive(:remove_package)
      provider.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
    end
  end

  describe "#action_install" do
    it "installs package if already not installed" do
      provider.load_current_resource
      expect(provider.installed_version).to eql(nil)
      expect(provider).to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).to be_updated_by_last_action
    end

    it "does not install package if already installed" do
      allow_package_info(new_resource.source, nil)
      allow_get_packages
      allow_package_info(nil, "Package_for_KB2664825~31bf3856ad364e35~amd64~~6.1.3.0")
      provider.load_current_resource
      expect(provider.installed_version).not_to eql(nil)
      expect(provider).not_to receive(:install_package)
      provider.run_action(:install)
      expect(new_resource).not_to be_updated_by_last_action
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

    before do
      new_resource.source = "#{ENV['TEMP']}/test6.1-kb2664825-v3-x64.cab"
      installed_package_list_obj = double(stdout: installed_package_list_stdout)
      allow(provider).to receive(:dism_command).with("/Get-Packages").and_return(installed_package_list_obj)
    end

    it "raises error for invalid source path or file" do
      expect { provider.load_current_resource }.to raise_error(Chef::Exceptions::Package, "DISM: The system cannot find the path or file specified.")
    end
  end
end
