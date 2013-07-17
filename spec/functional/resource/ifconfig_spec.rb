#
# Author:: Kaustubh Deorukhkar (<kaustubh@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'functional/resource/base'
require 'chef/mixin/shell_out'

describe Chef::Resource::Ifconfig, :unix_only do
  include Chef::Mixin::ShellOut

  let(:new_resource) do
    new_resource = Chef::Resource::Ifconfig.new('10.10.0.1', run_context)
    new_resource
  end

  let(:provider) do
    provider = new_resource.provider_for_action(new_resource.action)
    provider
  end

  let(:current_resource) do
    provider.load_current_resource
  end

  def network_interface_for_test
    # use loopback interface for tests
    case ohai[:platform]
    when :aix
      'lo0'
    else
      'lo'
    end
  end

  def network_interface_alias
    case ohai[:platform]
    when :aix
      network_interface_for_test
    else
      network_interface_for_test + ":10"
    end
  end

  # platform specific test setup and validation routines

  def setup_add_interface(resource)
    resource.device network_interface_alias
    resource.is_vip = true if ohai[:platform] == :aix
  end

  def interface_should_exists(interface)
    expect(shell_out("ifconfig #{@interface} | grep 10.10.0.1").exitstatus).to eq(0)
  end

  def interface_should_not_exists(interface)
    expect(shell_out("ifconfig #{@interface} | grep 10.10.0.1").exitstatus).to eq(1)
  end

  def interface_persistence_should_exists(interface)
    # TODO: for AIX query ODM
  end

  def interface_persistence_should_not_exists(interface)
    # TODO: for AIX query ODM
  end

  # Actual tests

  describe "#load_current_resource" do
    it 'should load given interface' do
      new_resource.device network_interface_for_test
      expect(current_resource.device).to eql(network_interface_for_test)
      expect(current_resource.inet_addr).to match(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
    end
  end

  describe "#action_add", ohai[:platform] != :aix do
    after do
      new_resource.run_action(:delete)
    end
    it "should add interface (vip)" do
      setup_add_interface(new_resource)
      new_resource.run_action(:add)
      interface_should_exists(network_interface_alias)
      interface_persistence_should_exists(network_interface_alias)
    end
  end

  describe "#action_enable", ohai[:platform] != :aix do
    after do
      new_resource.run_action(:delete)
    end
    it "should enable interface (vip)" do
      setup_add_interface(new_resource)
      new_resource.run_action(:enable)
      interface_should_exists(network_interface_alias)
    end
  end

  describe "#action_disable", ohai[:platform] != :aix do
    before do
      setup_add_interface(new_resource)
      new_resource.run_action(:add)
    end
    after do
      new_resource.run_action(:delete)
    end
    it "should disable interface (vip)" do
      new_resource.run_action(:disable)
      new_resource.should be_updated_by_last_action
      interface_should_not_exists(network_interface_alias)
    end
  end

  describe "#action_delete", ohai[:platform] != :aix do
    before do
      setup_add_interface(new_resource)
      new_resource.run_action(:add)
    end
    it "should delete interface (vip)" do
      new_resource.run_action(:delete)
      new_resource.should be_updated_by_last_action
      interface_should_not_exists(network_interface_alias)
      interface_persistence_should_not_exists(network_interface_alias)
    end
  end
end