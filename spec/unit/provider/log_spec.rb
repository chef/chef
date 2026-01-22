#
# Author:: Cary Penniman (<cary@rightscale.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::Log do

  let(:log_str) { "this is my test string to log" }

  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) { Chef::Resource::Log.new(log_str, run_context) }

  let(:provider) { new_resource.provider_for_action(:run) }

  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  before do
    allow(run_context).to receive(:logger).and_return(logger)
  end

  it "should write the string to the logger object at default level (info)" do
    expect(logger).to receive(:info).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the logger object at debug level" do
    new_resource.level :debug
    expect(logger).to receive(:debug).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the logger object at info level" do
    new_resource.level :info
    expect(logger).to receive(:info).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the logger object at warn level" do
    new_resource.level :warn
    expect(logger).to receive(:warn).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the logger object at error level" do
    new_resource.level :error
    expect(logger).to receive(:error).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should write the string to the logger object at fatal level" do
    new_resource.level :fatal
    expect(logger).to receive(:fatal).with(log_str).and_return(true)
    provider.run_action(:write)
  end

  it "should print the string in why-run mode" do
    Chef::Config[:why_run] = true
    expect(logger).to receive(:info).with(log_str).and_return(true)
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
