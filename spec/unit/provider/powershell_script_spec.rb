#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
describe Chef::Provider::PowershellScript, "action_run" do

  let(:powershell_version) { nil }
  let(:node) {
    node = Chef::Node.new
    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s
    if ! powershell_version.nil?
      node.default[:languages] = { powershell: { version: powershell_version } }
    end
    node
  }

  let(:provider) {
    empty_events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, empty_events)
    new_resource = Chef::Resource::PowershellScript.new('run some powershell code', run_context)
    Chef::Provider::PowershellScript.new(new_resource, run_context)
  }

  context 'when setting interpreter flags' do
    it "should set the -File flag as the last flag" do
      expect(provider.flags.split(' ').pop).to eq("-File")
    end

    let(:execution_policy_flag) do
      execution_policy_index = 0
      provider_flags = provider.flags.split(' ')
      execution_policy_specified = false

      provider_flags.find do | value |
        execution_policy_index += 1
        execution_policy_specified = value.downcase == '-ExecutionPolicy'.downcase
      end

      execution_policy = execution_policy_specified ? provider_flags[execution_policy_index] : nil
    end

    context 'when running with an unspecified PowerShell version' do
      let(:powershell_version) { nil }
      it "should set the -ExecutionPolicy flag to 'Unrestricted' by default" do
        expect(execution_policy_flag.downcase).to eq('unrestricted'.downcase)
      end
    end

    { '2.0' => 'Unrestricted',
      '2.5' => 'Unrestricted',
      '3.0' => 'Bypass',
      '3.6' => 'Bypass',
      '4.0' => 'Bypass',
      '5.0' => 'Bypass' }.each do | version_policy |
      let(:powershell_version) { version_policy[0].to_f }
      context "when running PowerShell version #{version_policy[0]}" do
        let(:powershell_version) { version_policy[0].to_f }
        it "should set the -ExecutionPolicy flag to '#{version_policy[1]}'" do
          expect(execution_policy_flag.downcase).to eq(version_policy[1].downcase)
        end
      end
    end
  end
end
