#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

describe Chef::Provider::Log::ChefLog do

  let(:log_str) { "this is my test string to log" }

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) { Chef::Resource::Log.new(log_str) }

  let(:provider) { Chef::Provider::Log::ChefLog.new(new_resource, run_context) }

  it "should write the string to the Chef::Log object at default level (info)" do
    expect(Chef::Log).to receive(:info).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the Chef::Log object at debug level" do
    new_resource.level :debug
    expect(Chef::Log).to receive(:debug).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the Chef::Log object at info level" do
    new_resource.level :info
    expect(Chef::Log).to receive(:info).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the Chef::Log object at warn level" do
    new_resource.level :warn
    expect(Chef::Log).to receive(:warn).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the Chef::Log object at error level" do
    new_resource.level :error
    expect(Chef::Log).to receive(:error).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the Chef::Log object at fatal level" do
    new_resource.level :fatal
    expect(Chef::Log).to receive(:fatal).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should print the string in why-run mode" do
    Chef::Config[:why_run] = true
    expect(Chef::Log).to receive(:info).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  context "when count_log_resource_updates is passed in knife.rb" do
    it "updates the resource count if count_log_resource_updates=true" do
      Chef::Config[:count_log_resource_updates] = true
      expect(new_resource).to receive(:updated_by_last_action)
      provider.run_action(:write)
    end

    it "doesn't update the resource count if count_log_resource_updates=false" do
      Chef::Config[:count_log_resource_updates] = false
      expect(new_resource).not_to receive(:updated_by_last_action)
      provider.run_action(:write)
    end
  end
end
