#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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
describe Chef::Provider::Breakpoint do

  before do
    @resource = Chef::Resource::Breakpoint.new
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @collection = double("resource collection")
    allow(@run_context).to receive(:resource_collection).and_return(@collection)
    @provider = Chef::Provider::Breakpoint.new(@resource, @run_context)
  end

  it "responds to load_current_resource" do
    expect(@provider).to respond_to(:load_current_resource)
  end

  it "gets the iterator from @collection and pauses it" do
    allow(Shell).to receive(:running?).and_return(true)
    @iterator = double("stepable_iterator")
    allow(@collection).to receive(:iterator).and_return(@iterator)
    expect(@iterator).to receive(:pause)
    @provider.action_break
    expect(@resource).to be_updated
  end

  it "doesn't pause the iterator if chef-shell isn't running" do
    allow(Shell).to receive(:running?).and_return(false)
    @iterator = double("stepable_iterator")
    allow(@collection).to receive(:iterator).and_return(@iterator)
    expect(@iterator).not_to receive(:pause)
    @provider.action_break
  end

end
