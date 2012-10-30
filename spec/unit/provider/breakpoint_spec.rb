#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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


require 'spec_helper'
describe Chef::Provider::Breakpoint do

  before do
    @resource = Chef::Resource::Breakpoint.new
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @collection = mock("resource collection")
    @run_context.stub!(:resource_collection).and_return(@collection)
    @provider = Chef::Provider::Breakpoint.new(@resource, @run_context)
  end

  it "responds to load_current_resource" do
    @provider.should respond_to(:load_current_resource)
  end

  it "gets the iterator from @collection and pauses it" do
    Shell.stub!(:running?).and_return(true)
    @iterator = mock("stepable_iterator")
    @collection.stub!(:iterator).and_return(@iterator)
    @iterator.should_receive(:pause)
    @provider.action_break
    @resource.should be_updated
  end

  it "doesn't pause the iterator if chef-shell isn't running" do
    Shell.stub!(:running?).and_return(false)
    @iterator = mock("stepable_iterator")
    @collection.stub!(:iterator).and_return(@iterator)
    @iterator.should_not_receive(:pause)
    @provider.action_break
  end

end
