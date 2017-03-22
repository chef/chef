#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Resource::Service do

  before(:each) do
    @resource = Chef::Resource::Service.new("chef")
  end

  it "should create a new Chef::Resource::Service" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Service)
  end

  it "should not set a provider unless node[:init_package] is defined as systemd" do
    expect(@resource.provider).to eq(nil)
  end

  it "should set the service_name to the first argument to new" do
    expect(@resource.service_name).to eql("chef")
  end

  it "should set the pattern to be the service name by default" do
    expect(@resource.pattern).to eql("chef")
  end

  it "should accept a string for the service name" do
    @resource.service_name "something"
    expect(@resource.service_name).to eql("something")
  end

  it "should accept a string for the service pattern" do
    @resource.pattern ".*"
    expect(@resource.pattern).to eql(".*")
  end

  it "should not accept a regexp for the service pattern" do
    expect do
      @resource.pattern /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service start command" do
    @resource.start_command "/etc/init.d/chef start"
    expect(@resource.start_command).to eql("/etc/init.d/chef start")
  end

  it "should not accept a regexp for the service start command" do
    expect do
      @resource.start_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service stop command" do
    @resource.stop_command "/etc/init.d/chef stop"
    expect(@resource.stop_command).to eql("/etc/init.d/chef stop")
  end

  it "should not accept a regexp for the service stop command" do
    expect do
      @resource.stop_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service status command" do
    @resource.status_command "/etc/init.d/chef status"
    expect(@resource.status_command).to eql("/etc/init.d/chef status")
  end

  it "should not accept a regexp for the service status command" do
    expect do
      @resource.status_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service restart command" do
    @resource.restart_command "/etc/init.d/chef restart"
    expect(@resource.restart_command).to eql("/etc/init.d/chef restart")
  end

  it "should not accept a regexp for the service restart command" do
    expect do
      @resource.restart_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service reload command" do
    @resource.reload_command "/etc/init.d/chef reload"
    expect(@resource.reload_command).to eql("/etc/init.d/chef reload")
  end

  it "should not accept a regexp for the service reload command" do
    expect do
      @resource.reload_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept a string for the service init command" do
    @resource.init_command "/etc/init.d/chef"
    expect(@resource.init_command).to eql("/etc/init.d/chef")
  end

  it "should not accept a regexp for the service init command" do
    expect do
      @resource.init_command /.*/
    end.to raise_error(ArgumentError)
  end

  it "should accept an array for options" do
    @resource.options ["-r", "-s"]
    expect(@resource.options).to eql(["-r", "-s"])
  end

  it "should accept a string for options" do
    @resource.options "-r"
    expect(@resource.options).to eql(["-r"])
  end

  it "should accept a string with multiple flags for options" do
    @resource.options "-r -s"
    expect(@resource.options).to eql(["-r", "-s"])
  end

  it "should not accept a boolean for options" do
    expect do
      @resource.options true
    end.to raise_error(ArgumentError)
  end

  %w{enabled running}.each do |attrib|
    it "should accept true for #{attrib}" do
      @resource.send(attrib, true)
      expect(@resource.send(attrib)).to eql(true)
    end

    it "should accept false for #{attrib}" do
      @resource.send(attrib, false)
      expect(@resource.send(attrib)).to eql(false)
    end

    it "should not accept a string for #{attrib}" do
      expect { @resource.send(attrib, "poop") }.to raise_error(ArgumentError)
    end

    it "should default all the feature support to nil" do
      support_hash = { :status => nil, :restart => nil, :reload => nil }
      expect(@resource.supports).to eq(support_hash)
    end

    it "should allow you to set what features this resource supports as a array" do
      support_array = [ :status, :restart ]
      support_hash = { :status => true, :restart => true }
      @resource.supports(support_array)
      expect(@resource.supports).to eq(support_hash)
    end

    it "should allow you to set what features this resource supports as a hash" do
      support_hash = { :status => true, :restart => true }
      @resource.supports(support_hash)
      expect(@resource.supports).to eq(support_hash)
    end
  end

  describe "when it has pattern and supports" do
    before do
      @resource.service_name("superfriend")
      @resource.enabled(true)
      @resource.running(false)
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:enabled]).to eql(true)
      expect(state[:running]).to eql(false)
    end

    it "returns the service name as its identity" do
      expect(@resource.identity).to eq("superfriend")
    end
  end
end
