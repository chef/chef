#
# Author:: Adam Edwards (<adamed@chef.io>)
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

require "support/shared/unit/execute_resource"
require "support/shared/unit/script_resource"

shared_examples_for "a Windows script resource" do
  it "should be a kind of Chef::Resource::WindowsScript" do
    expect(windows_script_resource).to be_a_kind_of(Chef::Resource)
    expect(windows_script_resource).to be_a_kind_of(Chef::Resource::WindowsScript)
  end

  context "when evaluating guards" do
    it "should have a default_guard_interpreter attribute that is the same as the resource" do
      expect(windows_script_resource.default_guard_interpreter).to eq(windows_script_resource.resource_name)
    end

    it "should default to using guard_interpreter attribute that is the same as the resource" do
      expect(windows_script_resource.guard_interpreter).to eq(windows_script_resource.resource_name)
    end

    it "should use a resource to evaluate the guard when guard_interpreter is not specified" do
      expect_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate).and_return(true)
      expect_any_instance_of(Chef::GuardInterpreter::DefaultGuardInterpreter).not_to receive(:evaluate)
      windows_script_resource.only_if "echo hi"
      expect(windows_script_resource.should_skip?(:run)).to eq(nil)
    end

    describe "when the guard is given a ruby block" do
      it "should evaluate the guard if the guard_interpreter is set to its default value" do
        windows_script_resource.only_if { true }
        expect(windows_script_resource.should_skip?(:run)).to eq(nil)
      end

      it "should raise an exception if the guard_interpreter is overridden from its default value" do
        windows_script_resource.guard_interpreter :bash
        windows_script_resource.only_if { true }
        expect { windows_script_resource.should_skip?(:run) }.to raise_error(ArgumentError)
      end
    end
  end

  context "script with a default guard interpreter" do
    let(:script_resource) { windows_script_resource }

    before { windows_script_resource.guard_interpreter :default }

    it_should_behave_like "a script resource"
  end
end
