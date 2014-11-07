#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

shared_examples_for "a script resource" do

  before(:each) do
    @resource = script_resource
  end

  it "should create a new Chef::Resource::Script" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Script)
  end

  it "should have a resource name of :script" do
    expect(@resource.resource_name).to eql(resource_name)
  end

  it "should set command to the argument provided to new" do
    expect(@resource.command).to eql(resource_instance_name)
  end

  it "should accept a string for the code" do
    @resource.code "hey jude"
    expect(@resource.code).to eql("hey jude")
  end

  it "should accept a string for the flags" do
    @resource.flags "-f"
    expect(@resource.flags).to eql("-f")
  end

  describe "when executing guards" do
    let(:resource) { @resource }

    before(:each) do
      node = Chef::Node.new

      node.automatic[:platform] = "debian"
      node.automatic[:platform_version] = "6.0"

      events = Chef::EventDispatch::Dispatcher.new
      run_context = Chef::RunContext.new(node, {}, events)
      resource.run_context = run_context
      resource.code 'echo hi'
    end

    it "inherits exactly the :cwd, :environment, :group, :path, :user, and :umask attributes from a parent resource class" do
      inherited_difference = Chef::Resource::Script.guard_inherited_attributes -
        [:cwd, :environment, :group, :path, :user, :umask ]

      expect(inherited_difference).to eq([])
    end

    it "when guard_interpreter is set to the default value, the guard command string should be evaluated by command execution and not through a resource" do
      expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:evaluate_block)
      expect_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).not_to receive(:evaluate_action)
      expect_any_instance_of(Chef::GuardInterpreter::DefaultGuardInterpreter).to receive(:evaluate).and_return(true)
      resource.only_if 'echo hi'
      expect(resource.should_skip?(:run)).to eq(nil)
    end

    it "when a valid guard_interpreter resource is specified, a block should be used to evaluate the guard" do
      expect_any_instance_of(Chef::GuardInterpreter::DefaultGuardInterpreter).not_to receive(:evaluate)
      expect_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(true)
      resource.guard_interpreter :script
      resource.only_if 'echo hi'
      expect(resource.should_skip?(:run)).to eq(nil)
    end
  end
end

