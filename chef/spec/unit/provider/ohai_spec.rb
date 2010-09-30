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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

require 'chef/run_context'

describe Chef::Provider::Ohai do
  before(:each) do
    # Copied from client_spec
    FQDN = "hostname.domainname"
    HOSTNAME = "hostname"
    PLATFORM = "example-platform"
    PLATFORM_VERSION = "example-platform"
    Chef::Config[:node_name] = FQDN
    mock_ohai = {
      :fqdn => FQDN,
      :hostname => HOSTNAME,
      :platform => PLATFORM,
      :platform_version => PLATFORM_VERSION,
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
    Chef::Platform.stub!(:find_platform_and_version).and_return({ "platform" => PLATFORM,
                                                                  "platform_version" => PLATFORM_VERSION})
    # Fake node with a dummy save
    @node = Chef::Node.new(HOSTNAME)
    @node.name(FQDN)
    @node.stub!(:save).and_return(@node)
    @run_context = Chef::RunContext.new(@node, {})
    @new_resource = Chef::Resource::Ohai.new("ohai_reload")
    ohai = Ohai::System.new
    ohai.all_plugins
    @node.process_external_attrs(ohai.data,{})

    @provider = Chef::Provider::Ohai.new(@new_resource, @run_context)
  end

  describe "when reloading ohai" do
    it "should cause node to pick up new values" do
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should == nil
      @provider.action_reload
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should == 'somevalue'
    end

    it "should reload a specific plugin and cause node to pick up new values" do
      @new_resource.plugin "someplugin"
      @provider.action_reload
      @node[:origdata].should == 'somevalue'
      @node[:newdata].should == 'somevalue'
    end
  end
end
