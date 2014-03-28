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

describe Chef::Resource::PowershellScript do

  before(:each) do
    node = Chef::Node.new

    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s

    run_context = Chef::RunContext.new(node, nil, nil)

    @resource = Chef::Resource::PowershellScript.new("powershell_unit_test", run_context)

  end

  it "should create a new Chef::Resource::PowershellScript" do
    @resource.should be_a_kind_of(Chef::Resource::PowershellScript)
  end

  context "when using guards" do
    let(:resource) { @resource }
    before(:each) do
      resource.stub(:run_action)
      resource.stub(:updated).and_return(true)
    end

    it "should allow guard interpreter to be set to Chef::Resource::Script" do
      resource.guard_interpreter(:script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end

    it "should allow guard interpreter to be set to Chef::Resource::Bash derived from Chef::Resource::Script" do
      resource.guard_interpreter(:bash)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end

    it "should allow guard interpreter to be set to Chef::Resource::PowershellScript derived indirectly from Chef::Resource::Script" do
      resource.guard_interpreter(:powershell_script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end
  end

  context "as a script running in Windows-based scripting language" do
    let(:resource_instance) { @resource }
    let(:resource_instance_name ) { @resource.command }
    let(:resource_name) { :powershell_script }
    let(:interpreter_file_name) { 'powershell.exe' }

    it_should_behave_like "a Windows script resource"
  end
end
