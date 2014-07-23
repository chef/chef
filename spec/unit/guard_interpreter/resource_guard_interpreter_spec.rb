#
# Author:: Adam Edwards (<adamed@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::GuardInterpreter::ResourceGuardInterpreter do
  before(:each) do
    node = Chef::Node.new

    node.default['kernel'] = Hash.new
    node.default['kernel'][:machine] = :x86_64.to_s

    run_context = Chef::RunContext.new(node, nil, nil)

    @resource = Chef::Resource.new('powershell_unit_test', run_context)
    @resource.stub(:run_action)
    @resource.stub(:updated).and_return(true)
  end

  describe 'when evaluating a guard resource' do
    let(:resource) { @resource }

    it 'should allow guard interpreter to be set to Chef::Resource::Script' do
      resource.guard_interpreter(:script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if('echo hi')
    end

    it 'should allow guard interpreter to be set to Chef::Resource::PowershellScript derived indirectly from Chef::Resource::Script' do
      resource.guard_interpreter(:powershell_script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if('echo hi')
    end

    it 'should raise an exception if guard_interpreter is set to a resource not derived from Chef::Resource::Script' do
      resource.guard_interpreter(:file)
      expect { resource.only_if('echo hi') }.to raise_error ArgumentError
    end
  end
end
