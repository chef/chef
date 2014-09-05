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

describe Chef::Platform::Rebooter do

  let(:reboot_info) do
    {
      :delay_mins => 5,
      :requested_by => "reboot resource functional test",
      :reason => "reboot resource spec test"
    }
  end

  def create_resource
    resource = Chef::Resource::Reboot.new(expected[:requested_by], run_context)
    resource.delay_mins(expected[:delay_mins])
    resource.reason(expected[:reason])
    resource
  end

  let(:run_context) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  let(:rebooter) { Chef::Platform::Rebooter }

  describe '#reboot_if_needed!' do

    # test that it's producing the correct commands.
    it 'should call #shell_out! when reboot has been requested' do
      run_context.request_reboot(reboot_info)

      expect(rebooter).to receive(:shell_out!).once
      expect(rebooter).to receive(:reboot_if_needed!).once.and_call_original
      rebooter.reboot_if_needed!(run_context.node)

      run_context.cancel_reboot
    end

    it 'should not call #shell_out! when reboot has not been requested' do
      expect(rebooter).to receive(:shell_out!).exactly(0).times
      expect(rebooter).to receive(:reboot_if_needed!).once.and_call_original
      rebooter.reboot_if_needed!(run_context.node)
    end
  end
end
