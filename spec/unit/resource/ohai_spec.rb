#
# Author:: Michael Leinartas (<mleinartas@gmail.com>)
# Copyright:: Copyright 2010-2016, Michael Leinartas
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

describe Chef::Resource::Ohai do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::Ohai.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:reload) }

  it "has a resource name of :ohai" do
    expect(resource.resource_name).to eql(:ohai)
  end

  it "sets the default action as :reload" do
    expect(resource.action).to eql([:reload])
  end

  it "supports :reload action" do
    expect { resource.action :reload }.not_to raise_error
  end

  it "allows you to set the plugin property" do
    resource.plugin "passwd"
    expect(resource.plugin).to eql("passwd")
  end

  describe "when it has a plugin value" do
    before do
      resource.name("test")
      resource.plugin("passwd")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:plugin]).to eq("passwd")
    end

    it "returns the name as its identity" do
      expect(resource.identity).to eq("test")
    end
  end

  describe "reload action" do
    before(:each) do
      # Copied from client_spec
      @fqdn = "hostname.domainname"
      @hostname = "hostname"
      @platform = "example-platform"
      @platform_version = "example-platform"
      Chef::Config[:node_name] = @fqdn
      mock_ohai = {
        fqdn: @fqdn,
        hostname: @hostname,
        platform: @platform,
        platform_version: @platform_version,
        data: {
          origdata: "somevalue",
        },
        data2: {
          origdata: "somevalue",
          newdata: "somevalue",
        },
      }
      allow(mock_ohai).to receive(:all_plugins).and_return(true)
      allow(mock_ohai).to receive(:data).and_return(mock_ohai[:data],
        mock_ohai[:data2])
      allow(Ohai::System).to receive(:new).and_return(mock_ohai)
      allow(Chef::Platform).to receive(:find_platform_and_version).and_return({ "platform" => @platform,
                                                                                "platform_version" => @platform_version })
      # Fake node with a dummy save
      node.name(@fqdn)
      allow(node).to receive(:save).and_return(node)
      ohai = Ohai::System.new
      ohai.all_plugins
      node.consume_external_attrs(ohai.data, {})
      node.automatic_attrs[:origdata] = "somevalue"
    end

    it "applies updated ohai data to the node" do
      expect(node[:origdata]).to eq("somevalue")
      expect(node[:newdata]).to be_nil
      provider.run_action(:reload)
      expect(node[:origdata]).to eq("somevalue")
      expect(node[:newdata]).to eq("somevalue")
    end

    it "supports reloading a specific plugin and causes node to pick up new values" do
      resource.plugin "someplugin"
      provider.run_action(:reload)
      expect(node[:origdata]).to eq("somevalue")
      expect(node[:newdata]).to eq("somevalue")
    end

    it "loads cookbook plugins when the ohai_segment_plugin_path directory exists and has content" do
      # Setup mock plugin path
      plugin_path = "/tmp/chef/ohai/cookbook_plugins"
      Chef::Config[:ohai_segment_plugin_path] = plugin_path

      # Mock that the directory exists and has content
      allow(Dir).to receive(:exist?).with(plugin_path).and_return(true)
      allow(Dir).to receive(:empty?).with(plugin_path).and_return(false)

      # Mock the ohai system
      ohai_mock = double("Ohai::System")
      config_mock = double("config")
      plugin_path_array = []

      allow(ohai_mock).to receive(:config).and_return(config_mock)
      allow(config_mock).to receive(:[]).with(:plugin_path).and_return(plugin_path_array)
      allow(ohai_mock).to receive(:all_plugins).with(nil)
      allow(ohai_mock).to receive(:data).and_return({})
      allow(Ohai::System).to receive(:new).and_return(ohai_mock)

      provider.run_action(:reload)

      # Verify that the plugin path was added to the ohai config
      expect(plugin_path_array).to include(plugin_path)
    end

    it "does not attempt to load cookbook plugins when the ohai_segment_plugin_path directory does not exist" do
      # Setup mock plugin path that doesn't exist
      plugin_path = "/tmp/chef/ohai/cookbook_plugins"
      Chef::Config[:ohai_segment_plugin_path] = plugin_path

      # Mock that the directory doesn't exist
      allow(Dir).to receive(:exist?).with(plugin_path).and_return(false)

      # Mock the ohai system
      ohai_mock = double("Ohai::System")
      config_mock = spy("config")

      allow(ohai_mock).to receive(:config).and_return(config_mock)
      allow(ohai_mock).to receive(:all_plugins).with(nil)
      allow(ohai_mock).to receive(:data).and_return({})
      allow(Ohai::System).to receive(:new).and_return(ohai_mock)

      provider.run_action(:reload)

      # Verify that the plugin path configuration was not accessed since directory doesn't exist
      expect(config_mock).not_to have_received(:[]).with(:additional_plugin_path)
    end

    it "does not attempt to load cookbook plugins when the ohai_segment_plugin_path directory is empty" do
      # Setup mock plugin path that exists but is empty
      plugin_path = "/tmp/chef/ohai/cookbook_plugins"
      Chef::Config[:ohai_segment_plugin_path] = plugin_path

      # Mock that the directory exists but is empty
      allow(Dir).to receive(:exist?).with(plugin_path).and_return(true)
      allow(Dir).to receive(:empty?).with(plugin_path).and_return(true)

      # Mock the ohai system
      ohai_mock = double("Ohai::System")
      config_mock = spy("config")

      allow(ohai_mock).to receive(:config).and_return(config_mock)
      allow(ohai_mock).to receive(:all_plugins).with(nil)
      allow(ohai_mock).to receive(:data).and_return({})
      allow(Ohai::System).to receive(:new).and_return(ohai_mock)

      provider.run_action(:reload)

      # Verify that the plugin path configuration was not accessed since directory is empty
      expect(config_mock).not_to have_received(:[]).with(:additional_plugin_path)
    end
  end
end
