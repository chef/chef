#
# Author:: Chris Doherty <cdoherty@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.
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

describe Chef::Resource::Reboot do

  let(:expected) do
    {
      :delay_mins => 5,
      :requested_by => "reboot resource functional test",
      :reason => "reboot resource spec test"
    }
  end

  def create_resource
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    resource = Chef::Resource::Reboot.new(expected[:requested_by], run_context)
    resource.delay_mins(expected[:delay_mins])
    resource.reason(expected[:reason])
    resource
  end

  let(:resource) do
    create_resource
  end

  # TODO: decide on a behavior for multiple :request and/or :cancel calls, and test for it.

  describe "the request action" do
    before do
      resource.run_action(:request)
    end

    after do
      resource.run_context.cancel_reboot
    end

    it 'should have modified the run context correctly' do
      reboot_info = resource.run_context.reboot_info
      expect(reboot_info.keys.sort).to eq([:delay_mins, :reason, :requested_by, :timestamp])
      expect(reboot_info[:delay_mins]).to eq(expected[:delay_mins])
      expect(reboot_info[:reason]).to eq(expected[:reason])
      expect(reboot_info[:requested_by]).to eq(expected[:requested_by])
    end
  end

  describe "the cancel action" do
    before do
      resource.run_context.request_reboot(expected)
      resource.run_action(:cancel)
    end

    it 'should have cleared the run context reboot data' do
      expect(resource.run_context.reboot_info).to eq({})
    end
  end
end
