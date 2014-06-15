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

require 'support/shared/unit/execute_resource'
require 'support/shared/unit/script_resource'

shared_examples_for "a Windows script resource" do
  before(:each) do
    node = Chef::Node.new

    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s

    run_context = Chef::RunContext.new(node, nil, nil)

    @resource = resource_instance

  end

  it "should be a kind of Chef::Resource::WindowsScript" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::WindowsScript)
  end

  context "when evaluating guards" do
    it "should default to using guard_interpreter attribute that is the same as the resource" do
      @resource.guard_interpreter.should == @resource.resource_name
    end

    it "should use a resource to evaluate the guard when guard_interpreter is not specified" do
      Chef::GuardInterpreter::ResourceGuardInterpreter.any_instance.should_receive(:evaluate_action).and_return(true)
      Chef::GuardInterpreter::DefaultGuardInterpreter.any_instance.should_not_receive(:evaluate)
      @resource.only_if 'echo hi'
      @resource.should_skip?(:run).should == nil
    end
  end

  context "script with a default guard interpreter" do
    let(:script_resource) do
      resource_instance.guard_interpreter :default
      resource_instance
    end
    it_should_behave_like "a script resource"
  end

end

