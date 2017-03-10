#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "functional/resource/base"
require "chef/mixin/shell_out"

# run this test only for following platforms.
include_flag = !(%w{ubuntu centos aix}.include?(ohai[:platform]))

describe Chef::Resource::Ifconfig, :requires_root, :skip_travis, :external => include_flag do
  # This test does not work in travis because there is no eth0

  include Chef::Mixin::ShellOut

  let(:new_resource) do
    new_resource = Chef::Resource::Ifconfig.new("10.10.0.1", run_context)
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  let(:current_resource) do
    provider.load_current_resource
  end

  def lo_interface_for_test
    # use loopback interface for tests
    case ohai[:platform]
    when "aix"
      "lo0"
    else
      "lo"
    end
  end

  def fetch_first_interface_name
    shell_out("ifconfig | grep Ethernet | head -1 | cut -d' ' -f1").stdout.strip
  end

  # **Caution: any updates to core interfaces can be risky.
  def en0_interface_for_test
    case ohai[:platform]
    when "aix"
      "en0"
    when "ubuntu"
      fetch_first_interface_name
    else
      "eth0"
    end
  end

  def network_interface_alias(interface)
    case ohai[:platform]
    when "aix"
      interface
    else
      interface + ":10"
    end
  end

  # platform specific test setup and validation routines

  def setup_add_interface(resource)
    resource.device network_interface_alias(en0_interface_for_test)
  end

  def setup_enable_interface(resource)
    resource.device network_interface_alias(en0_interface_for_test)
  end

  def interface_should_exists(interface)
    expect(shell_out("ifconfig #{@interface} | grep 10.10.0.1").exitstatus).to eq(0)
  end

  def interface_should_not_exists(interface)
    expect(shell_out("ifconfig #{@interface} | grep 10.10.0.1").exitstatus).to eq(1)
  end

  def interface_persistence_should_exists(interface)
    case ohai[:platform]
    when "aix"
      expect(shell_out("lsattr -E -l #{@interface} | grep 10.10.0.1").exitstatus).to eq(0)
    else
    end
  end

  def interface_persistence_should_not_exists(interface)
    case ohai[:platform]
    when "aix"
      expect(shell_out("lsattr -E -l #{@interface} | grep 10.10.0.1").exitstatus).to eq(1)
    else
    end
  end

  # Actual tests

  describe "#load_current_resource" do
    it "should load given interface" do
      new_resource.device lo_interface_for_test
      expect(current_resource.device).to eql(lo_interface_for_test)
      expect(current_resource.inet_addr).to match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    end
  end

  exclude_test = ohai[:platform] != "ubuntu"
  describe "#action_add", :external => exclude_test do
    after do
      new_resource.run_action(:delete)
    end
    it "should add interface (vip)" do
      setup_add_interface(new_resource)
      new_resource.run_action(:add)
      interface_should_exists(network_interface_alias(en0_interface_for_test))
      interface_persistence_should_exists(network_interface_alias(en0_interface_for_test))
    end
  end

  describe "#action_enable", :external => exclude_test do
    after do
      new_resource.run_action(:disable)
    end
    it "should enable interface (vip)" do
      setup_enable_interface(new_resource)
      new_resource.run_action(:enable)
      interface_should_exists(network_interface_alias(en0_interface_for_test))
    end
  end

  describe "#action_disable", :external => exclude_test do
    before do
      setup_enable_interface(new_resource)
      new_resource.run_action(:enable)
    end
    it "should disable interface (vip)" do
      new_resource.run_action(:disable)
      expect(new_resource).to be_updated_by_last_action
      interface_should_not_exists(network_interface_alias(en0_interface_for_test))
    end
  end

  describe "#action_delete", :external => exclude_test do
    before do
      setup_add_interface(new_resource)
      new_resource.run_action(:add)
    end
    it "should delete interface (vip)" do
      new_resource.run_action(:delete)
      expect(new_resource).to be_updated_by_last_action
      interface_should_not_exists(network_interface_alias(en0_interface_for_test))
      interface_persistence_should_not_exists(network_interface_alias(en0_interface_for_test))
    end
  end
end
