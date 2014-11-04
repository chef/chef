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
    allow(STDOUT).to receive(:tty?).and_return(true)
  end

  let(:opts) do
    {
      timeout:	@new_resource.timeout,
      returns:	@new_resource.returns,
      log_level: :info,
      log_tag: @new_resource.to_s,
      live_stream: STDOUT
    }
  end

  it "should execute foo_resource" do
    allow(@provider).to receive(:load_current_resource)
    expect(@provider).to receive(:shell_out!).with(@new_resource.command, opts)
    expect(@provider).to receive(:converge_by).with("execute foo_resource").and_call_original
    expect(Chef::Log).not_to receive(:warn)

    @provider.run_action(:run)
    expect(@new_resource).to be_updated
  end

  it "should honor sensitive attribute" do
    @new_resource.sensitive true
    @provider = Chef::Provider::Execute.new(@new_resource, @run_context)
    allow(@provider).to receive(:load_current_resource)
    # Since the resource is sensitive, it should not have :live_stream set
    expect(@provider).to receive(:shell_out!).with(@new_resource.command, opts.reject { |k| k == :live_stream })
    expect(Chef::Log).not_to receive(:warn)
    expect(@provider).to receive(:converge_by).with("execute sensitive resource").and_call_original
    @provider.run_action(:run)
    expect(@new_resource).to be_updated
  end

  it "should do nothing if the sentinel file exists" do
    allow(@provider).to receive(:load_current_resource)
    expect(File).to receive(:exists?).with(@new_resource.creates).and_return(true)
    expect(@provider).not_to receive(:shell_out!)
    expect(Chef::Log).not_to receive(:warn)

    @provider.run_action(:run)
    expect(@new_resource).not_to be_updated
  end

  it "should respect cwd options for 'creates'" do
    @new_resource.cwd "/tmp"
    @new_resource.creates "foo_resource"
    allow(@provider).to receive(:load_current_resource)
    expect(File).to receive(:exists?).with(@new_resource.creates).and_return(false)
    expect(File).to receive(:exists?).with(File.join("/tmp", @new_resource.creates)).and_return(true)
    expect(Chef::Log).not_to receive(:warn)
    expect(@provider).not_to receive(:shell_out!)

    @provider.run_action(:run)
    expect(@new_resource).not_to be_updated
  end

  it "should warn if user specified relative path without cwd" do
    @new_resource.creates "foo_resource"
    allow(@provider).to receive(:load_current_resource)
    expect(Chef::Log).to receive(:warn).with(/relative path/)
    expect(File).to receive(:exists?).with(@new_resource.creates).and_return(true)
    expect(@provider).not_to receive(:shell_out!)

    @provider.run_action(:run)
    expect(@new_resource).not_to be_updated
  end
end

