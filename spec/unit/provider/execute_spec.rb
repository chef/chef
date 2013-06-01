#
# Author:: Prajakta Purohit (<prajakta@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
#require 'spec_helper'

describe Chef::Provider::Execute do
  before do
    @node = Chef::Node.new
    @cookbook_collection = Chef::CookbookCollection.new([])
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    @new_resource = Chef::Resource::Execute.new("foo_resource", @run_context)
    @new_resource.timeout 3600
    @new_resource.returns 0
    @new_resource.creates "/foo_resource"
    @provider = Chef::Provider::Execute.new(@new_resource, @run_context)
    @current_resource = Chef::Resource::Ifconfig.new("foo_resource", @run_context)
    @provider.current_resource = @current_resource
    Chef::Log.level = :info 
    # FIXME: There should be a test for how STDOUT.tty? changes the live_stream option being passed
    STDOUT.stub!(:tty?).and_return(true)
  end


  it "should execute foo_resource" do
    @provider.stub!(:load_current_resource)
    opts = {}
    opts[:timeout] = @new_resource.timeout
    opts[:returns] = @new_resource.returns
    opts[:log_level] = :info
    opts[:log_tag] = @new_resource.to_s
    opts[:live_stream] = STDOUT
    @provider.should_receive(:shell_out!).with(@new_resource.command, opts)
    Chef::Log.should_not_receive(:warn)

    @provider.run_action(:run)
    @new_resource.should be_updated
  end

  it "should do nothing if the sentinel file exists" do
    @provider.stub!(:load_current_resource)
    File.should_receive(:exists?).with(@new_resource.creates).and_return(true)
    @provider.should_not_receive(:shell_out!)
    Chef::Log.should_not_receive(:warn)

    @provider.run_action(:run)
    @new_resource.should_not be_updated
  end

  it "should respect cwd options for 'creates'" do
    @new_resource.cwd "/tmp"
    @new_resource.creates "foo_resource"
    @provider.stub!(:load_current_resource)
    File.should_receive(:exists?).with(@new_resource.creates).and_return(false)
    File.should_receive(:exists?).with(File.join("/tmp", @new_resource.creates)).and_return(true)
    Chef::Log.should_not_receive(:warn)
    @provider.should_not_receive(:shell_out!)

    @provider.run_action(:run)
    @new_resource.should_not be_updated
  end 

  it "should warn if user specified relative path without cwd" do
    @new_resource.creates "foo_resource"
    @provider.stub!(:load_current_resource)
    Chef::Log.should_receive(:warn).with(/relative path/)
    File.should_receive(:exists?).with(@new_resource.creates).and_return(true)
    @provider.should_not_receive(:shell_out!)

    @provider.run_action(:run)
    @new_resource.should_not be_updated
  end
end

