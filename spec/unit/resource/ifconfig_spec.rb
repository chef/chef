#
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Joe Williams
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

describe Chef::Resource::Ifconfig do

  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @resource = Chef::Resource::Ifconfig.new("fakey_fakerton", @run_context)
  end

  describe "when it has target, hardware address, inet address, and a mask" do
    before do
      @resource.device("charmander")
      @resource.target("team_rocket")
      @resource.hwaddr("11.2223.223")
      @resource.inet_addr("434.2343.23")
      @resource.mask("255.255.545")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:inet_addr]).to eq("434.2343.23")
      expect(state[:mask]).to eq("255.255.545")
    end

    it "returns the device as its identity" do
      expect(@resource.identity).to eq("charmander")
    end
  end

  shared_examples "being a platform based on an old Debian" do |platform, version|
    before do
      @node.automatic_attrs[:os] = "linux"
      @node.automatic_attrs[:platform_family] = "debian"
      @node.automatic_attrs[:platform] = platform
      @node.automatic_attrs[:platform_version] = version
    end

    it "should use an ordinary Provider::Ifconfig as a provider for #{platform} #{version}" do
      expect(@resource.provider_for_action(:add).class).to eq(Chef::Provider::Ifconfig)
    end
  end

  shared_examples "being a platform based on RedHat" do |platform, version|
    before do
      @node.automatic_attrs[:os] = "linux"
      @node.automatic_attrs[:platform_family] = "rhel"
      @node.automatic_attrs[:platform] = platform
      @node.automatic_attrs[:platform_version] = version
    end

    it "should use an Provider::Ifconfig::Redhat as a provider for #{platform} #{version}" do
      expect(@resource.provider_for_action(:add)).to be_a_kind_of(Chef::Provider::Ifconfig::Redhat)
    end
  end

  shared_examples "being a platform based on a recent Debian" do |platform, version|
    before do
      @node.automatic_attrs[:os] = "linux"
      @node.automatic_attrs[:platform_family] = "debian"
      @node.automatic_attrs[:platform] = platform
      @node.automatic_attrs[:platform_version] = version
    end

    it "should use an Ifconfig::Debian as a provider for #{platform} #{version}" do
      expect(@resource.provider_for_action(:add)).to be_a_kind_of(Chef::Provider::Ifconfig::Debian)
    end
  end

  describe "when it is a RedHat platform" do
    it_should_behave_like "being a platform based on RedHat", "redhat", "4.0"
  end

  describe "when it is an old Debian platform" do
    it_should_behave_like "being a platform based on an old Debian", "debian", "6.0"
  end

  describe "when it is a new Debian platform" do
    it_should_behave_like "being a platform based on a recent Debian", "debian", "7.0"
  end

  describe "when it is an old Ubuntu platform" do
    it_should_behave_like "being a platform based on an old Debian", "ubuntu", "11.04"
  end

  describe "when it is a new Ubuntu platform" do
    it_should_behave_like "being a platform based on a recent Debian", "ubuntu", "11.10"
  end

end
