#
# Author:: Kapil Chouhan (<kapil.chouhan@msystechnologies.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Provider::Package::Deb do
  let(:node) do
    node = Chef::Node.new
    node.automatic_attrs[:platform] = :just_testing
    node.automatic_attrs[:platform_version] = :just_testing
    node
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) { Chef::Resource::AptPackage.new("emacs", run_context) }
  let(:current_resource) { Chef::Resource::AptPackage.new("emacs", run_context) }
  let(:candidate_version) { "1.0" }
  let(:provider) do
    provider = Chef::Provider::Package::Apt.new(new_resource, run_context) { include Chef::Provider::Package::Deb }
    provider.current_resource = current_resource
    provider.candidate_version = candidate_version
    provider
  end

  before do
    allow(run_context).to receive(:logger).and_return(logger)
  end

  describe "when reconfiguring the package" do
    before(:each) do
      allow(provider).to receive(:reconfig_package).and_return(true)
    end

    context "when reconfigure the package" do
      it "reconfigure the package and update the resource" do
        allow(provider).to receive(:get_current_versions).and_return("1.0")
        allow(new_resource).to receive(:response_file).and_return(true)
        expect(provider).to receive(:get_preseed_file).and_return("/var/cache/preseed-test")
        allow(provider).to receive(:preseed_package).and_return(true)
        allow(provider).to receive(:reconfig_package).and_return(true)
        expect(logger).to receive(:info).with("apt_package[emacs] reconfigured")
        expect(provider).to receive(:reconfig_package)
        provider.run_action(:reconfig)
        expect(new_resource).to be_updated
        expect(new_resource).to be_updated_by_last_action
      end
    end

    context "when not reconfigure the package" do
      it "does not reconfigure the package if the package is not installed" do
        allow(provider).to receive(:get_current_versions).and_return(nil)
        allow(provider.load_current_resource).to receive(:version).and_return(nil)
        expect(logger).to receive(:debug).with("apt_package[emacs] is NOT installed - nothing to do")
        expect(provider).not_to receive(:reconfig_package)
        provider.run_action(:reconfig)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "does not reconfigure the package if no response_file is given" do
        allow(provider).to receive(:get_current_versions).and_return("1.0")
        allow(new_resource).to receive(:response_file).and_return(nil)
        expect(logger).to receive(:debug).with("apt_package[emacs] no response_file provided - nothing to do")
        expect(provider).not_to receive(:reconfig_package)
        provider.run_action(:reconfig)
        expect(new_resource).not_to be_updated_by_last_action
      end

      it "does not reconfigure the package if the response_file has not changed" do
        allow(provider).to receive(:get_current_versions).and_return("1.0")
        allow(new_resource).to receive(:response_file).and_return(true)
        expect(provider).to receive(:get_preseed_file).and_return(false)
        allow(provider).to receive(:preseed_package).and_return(false)
        expect(logger).to receive(:debug).with("apt_package[emacs] preseeding has not changed - nothing to do")
        expect(provider).not_to receive(:reconfig_package)
        provider.run_action(:reconfig)
        expect(new_resource).not_to be_updated_by_last_action
      end
    end
  end

  describe "Subclass with use_multipackage_api" do
    class MyDebianPackageResource < Chef::Resource::Package
    end

    class MyDebianPackageProvider < Chef::Provider::Package
      include Chef::Provider::Package::Deb
      use_multipackage_api
    end
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:new_resource) { MyDebianPackageResource.new("installs the packages") }
    let(:current_resource) { MyDebianPackageResource.new("installs the packages") }
    let(:provider) do
      provider = MyDebianPackageProvider.new(new_resource, run_context)
      provider.current_resource = current_resource
      provider
    end

    it "has use_multipackage_api? methods on the class and instance" do
      expect(MyDebianPackageProvider.use_multipackage_api?).to be true
      expect(provider.use_multipackage_api?).to be true
    end

    it "when user passes string to package_name, passes arrays to reconfig_package" do
      new_resource.package_name "vim"
      current_resource.package_name "vim"
      current_resource.version [ "1.0" ]
      allow(new_resource).to receive(:response_file).and_return(true)
      allow(new_resource).to receive(:resource_name).and_return(:apt_package)
      expect(provider).to receive(:get_preseed_file).and_return("/var/cache/preseed-test")
      allow(provider).to receive(:preseed_package).and_return(true)
      allow(provider).to receive(:reconfig_package).and_return(true)
      expect(provider).to receive(:reconfig_package).with([ "vim" ]).and_return(true)
      provider.run_action(:reconfig)
      expect(new_resource).to be_updated_by_last_action
    end
  end
end
