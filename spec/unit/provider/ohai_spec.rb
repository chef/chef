#
# Author:: Michael Leinartas (<mleinartas@gmail.com>)
# Copyright:: Copyright (c) 2010 Michael Leinartas
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

require 'chef/run_context'

describe Chef::Provider::Ohai do
  before(:each) do
    # Copied from client_spec
    @fqdn = "hostname.domainname"
    @hostname = "hostname"
    @platform = "example-platform"
    @platform_version = "example-platform"
    Chef::Config[:node_name] = @fqdn
    mock_ohai = {
      :fqdn => @fqdn,
      :hostname => @hostname,
      :platform => @platform,
      :platform_version => @platform_version,
      :data => {
        :origdata => "somevalue"
      },
      :data2 => {
        :origdata => "somevalue",
        :newdata => "somevalue"
      }
    }
    mock_ohai.stub!(:all_plugins).and_return(true)
    mock_ohai.stub!(:require_plugin).and_return(true)
    mock_ohai.stub!(:data).and_return(mock_ohai[:data],
                                      mock_ohai[:data2])
    Ohai::System.stub!(:new).and_return(mock_ohai)
    Chef::Platform.stub!(:find_platform_and_version).and_return({ "platform" => @platform,
                                                                  "platform_version" => @platform_version})
    # Fake node with a dummy save
    @node = Chef::Node.new
    @node.name(@fqdn)
    @node.stub!(:save).and_return(@node)
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Ohai.new("ohai_reload")
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.consume_external_attrs(ohai.data,{})

    @provider = Chef::Provider::Ohai.new(@new_resource, @run_context)
  end

  describe "when reloading ohai" do
    before do
      @node.automatic_attrs[:origdata] = 'somevalue'
    end

    it "applies updated ohai data to the node" do
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should be_nil
      @provider.run_action(:reload)
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should == 'somevalue'
    end

    it "should reload a specific plugin and cause node to pick up new values" do
      @new_resource.plugin "someplugin"
      @provider.run_action(:reload)
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should == 'somevalue'
    end
  end
end
