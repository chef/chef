#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
require "chef/provider/package/cab"

describe Chef::Resource::MsuPackage, :win2012r2_only do

  let(:package_name) { "Package_for_KB2959977" }
  let(:package_source) { "https://download.microsoft.com/download/3/B/3/3B320C07-B7B1-41E5-81F4-79EBC02DF7D3/Windows8.1-KB2959977-x64.msu" }

  let(:new_resource) { Chef::Resource::CabPackage.new("windows_test_pkg") }
  let(:cab_provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::Package::Cab.new(new_resource, run_context)
  end

  subject do
    new_resource = Chef::Resource::MsuPackage.new("test msu package", run_context)
    new_resource.package_name package_name
    new_resource.source package_source
    new_resource
  end

  context "installing package" do
    after { remove_package }

    it "installs the package successfully" do
      subject.run_action(:install)
      found_packages = cab_provider.installed_packages.select { |p| p["package_identity"] =~ /^#{package_name}~/ }
      expect(found_packages.length).to be == 1
    end
  end

  context "removing a package" do
    it "removes an installed package" do
      subject.run_action(:install)
      remove_package
      found_packages = cab_provider.installed_packages.select { |p| p["package_identity"] =~ /^#{package_name}~/ }
      expect(found_packages.length).to be == 0
    end
  end

  context "when an invalid msu package is given" do
    def package_name
      "Package_for_KB2859903"
    end

    def package_source
      "https://download.microsoft.com/download/5/2/B/52BE95BF-22D8-4415-B644-0FDF398F6D96/IE10-Windows6.1-KB2859903-x86.msu"
    end

    it "raises error while installing" do
      expect { subject.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "raises error while removing" do
      expect { subject.run_action(:remove) }.to raise_error(Chef::Exceptions::Package)
    end
  end

  def remove_package
    pkg_to_remove = Chef::Resource::MsuPackage.new(package_name, run_context)
    pkg_to_remove.source = package_source
    pkg_to_remove.run_action(:remove)
  end
end
