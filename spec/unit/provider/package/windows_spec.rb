#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'spec_helper'

describe Chef::Provider::Package::Windows, :windows_only do
  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:new_resource) { Chef::Resource::WindowsPackage.new("calculator.msi") }
  let(:provider) { Chef::Provider::Package::Windows.new(new_resource, run_context) }

  describe "load_current_resource" do
    before(:each) do
      allow(Chef::Util::PathHelper).to receive(:validate_path)
      allow(provider).to receive(:package_provider).and_return(double('package_provider',
          :installed_version => "1.0", :package_version => "2.0"))
    end

    it "creates a current resource with the name of the new resource" do
      provider.load_current_resource
      expect(provider.current_resource).to be_a(Chef::Resource::WindowsPackage)
      expect(provider.current_resource.name).to eql("calculator.msi")
    end

    it "sets the current version if the package is installed" do
      provider.load_current_resource
      expect(provider.current_resource.version).to eql("1.0")
    end

    it "sets the version to be installed" do
      provider.load_current_resource
      expect(provider.new_resource.version).to eql("2.0")
    end
  end

  describe "package_provider" do
    it "checks that the source path is valid" do
      expect(Chef::Util::PathHelper).to receive(:validate_path)
      provider.package_provider
    end

    it "sets the package provider to MSI if the the installer type is :msi" do
      allow(provider).to receive(:installer_type).and_return(:msi)
      expect(provider.package_provider).to be_a(Chef::Provider::Package::Windows::MSI)
    end

    it "raises an error if the installer_type is unknown" do
      allow(provider).to receive(:installer_type).and_return(:apt_for_windows)
      expect { provider.package_provider }.to raise_error
    end
  end

  describe "installer_type" do
    it "it returns @installer_type if it is set" do
      provider.new_resource.installer_type(:downeaster)
      expect(provider.installer_type).to eql(:downeaster)
    end

    it "sets installer_type to msi if the source ends in .msi" do
      provider.new_resource.source("microsoft_installer.msi")
      expect(provider.installer_type).to eql(:msi)
    end

    it "raises an error if it cannot determine the installer type" do
      provider.new_resource.installer_type(nil)
      provider.new_resource.source("tomfoolery.now")
      expect { provider.installer_type }.to raise_error(ArgumentError)
    end
  end
end
