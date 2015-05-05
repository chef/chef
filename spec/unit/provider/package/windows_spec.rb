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
  before(:each) do
    allow(Chef::Util::PathHelper).to receive(:windows?).and_return(true)
    allow(Chef::FileCache).to receive(:create_cache_path).with("package/").and_return(cache_path)
  end

  let(:node) { double('Chef::Node') }
  let(:events) { double('Chef::Events').as_null_object }  # mock all the methods
  let(:run_context) { double('Chef::RunContext', :node => node, :events => events) }
  let(:resource_source) { 'calculator.msi' }
  let(:new_resource) { Chef::Resource::WindowsPackage.new(resource_source) }
  let(:provider) { Chef::Provider::Package::Windows.new(new_resource, run_context) }
  let(:cache_path) { 'c:\\cache\\' }

  describe "load_current_resource" do
    shared_examples "a local file" do
      before(:each) do
        allow(Chef::Util::PathHelper).to receive(:validate_path)
        allow(provider).to receive(:package_provider).and_return(double('package_provider',
          :installed_version => "1.0", :package_version => "2.0"))
      end

      it "creates a current resource with the name of the new resource" do
        provider.load_current_resource
        expect(provider.current_resource).to be_a(Chef::Resource::WindowsPackage)
        expect(provider.current_resource.name).to eql(resource_source)
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

    context "when the source is a uri" do
      let(:resource_source) { 'https://foo.bar/calculator.msi' }

      context "when the source has not been downloaded" do
        before(:each) do
          allow(provider).to receive(:download_file_missing?).and_return(true)
        end
        it "sets the current version to unknown" do
          provider.load_current_resource
          expect(provider.current_resource.version).to eql("unknown")
        end
      end

      context "when the source has been downloaded" do
        before(:each) do
          allow(provider).to receive(:download_file_missing?).and_return(false)
        end
        it_behaves_like "a local file"
      end
    end

    context "when source is a local file" do
      it_behaves_like "a local file"
    end
  end

  describe "package_provider" do
    shared_examples "a local file" do
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

    context "when the source is a uri" do
      let(:resource_source) { 'https://foo.bar/calculator.msi' }

      context "when the source has not been downloaded" do
        before(:each) do
          allow(provider).to receive(:should_download?).and_return(true)
        end

        it "should create a package provider with source pointing at the local file" do
          expect(Chef::Provider::Package::Windows::MSI).to receive(:new) do |r|
            expect(r.source).to eq("#{cache_path}#{::File.basename(resource_source)}")
          end
          provider.package_provider
        end

        it_behaves_like "a local file"
      end

      context "when the source has been downloaded" do
        before(:each) do
          allow(provider).to receive(:should_download?).and_return(false)
        end
        it_behaves_like "a local file"
      end
    end

    context "when source is a local file" do
      it_behaves_like "a local file"
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
