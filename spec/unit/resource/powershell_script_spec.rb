#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::PowershellScript do

  let(:resource) do
    node = Chef::Node.new

    node.default["kernel"] = {}
    node.default["kernel"][:machine] = :x86_64.to_s
    node.automatic[:os] = "windows"

    run_context = Chef::RunContext.new(node, nil, nil)

    Chef::Resource::PowershellScript.new("powershell_unit_test", run_context)
  end

  it "creates a new Chef::Resource::PowershellScript" do
    expect(resource).to be_a_kind_of(Chef::Resource::PowershellScript)
  end

  it "sets convert_boolean_return to false by default" do
    expect(resource.convert_boolean_return).to eq(false)
  end

  it "returns the value for convert_boolean_return that was set" do
    resource.convert_boolean_return true
    expect(resource.convert_boolean_return).to eq(true)
    resource.convert_boolean_return false
    expect(resource.convert_boolean_return).to eq(false)
  end

  context "when using guards" do
    before(:each) do
      allow(resource).to receive(:run_action)
      allow(resource).to receive(:updated).and_return(true)
    end

    it "inherits exactly the :cwd, :environment, :group, :path, :user, :umask, :architecture, :elevated, :interpreter properties from a parent resource class" do
      inherited_difference = Chef::Resource::PowershellScript.guard_inherited_attributes -
        %i{cwd environment group path user umask architecture elevated interpreter}

      expect(inherited_difference).to eq([])
    end

    it "allows guard interpreter to be set to Chef::Resource::Script" do
      resource.guard_interpreter(:script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end

    it "allows guard interpreter to be set to Chef::Resource::Bash derived from Chef::Resource::Script" do
      resource.guard_interpreter(:bash)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end

    it "allows guard interpreter to be set to Chef::Resource::PowershellScript derived indirectly from Chef::Resource::Script" do
      resource.guard_interpreter(:powershell_script)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(false)
      resource.only_if("echo hi")
    end

    it "enables convert_boolean_return by default for guards in the context of powershell_script when no guard params are specified" do
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:evaluate_action).and_return(true)
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:block_from_attributes).with(
        { convert_boolean_return: true, code: "$true" }
      ).and_return(Proc.new {})
      resource.only_if("$true")
    end

    it "enables convert_boolean_return by default for guards in non-Chef::Resource::Script derived resources when no guard params are specified" do
      node = Chef::Node.new
      run_context = Chef::RunContext.new(node, nil, nil)
      file_resource = Chef::Resource::File.new("idontexist", run_context)
      file_resource.guard_interpreter :powershell_script

      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:block_from_attributes).with(
        { convert_boolean_return: true, code: "$true" }
      ).and_return(Proc.new {})
      resource.only_if("$true")
    end

    it "enables convert_boolean_return by default for guards in the context of powershell_script when guard params are specified" do
      guard_parameters = { cwd: "/etc/chef", architecture: :x86_64 }
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:block_from_attributes).with(
        { convert_boolean_return: true, code: "$true" }.merge(guard_parameters)
      ).and_return(Proc.new {})
      resource.only_if("$true", guard_parameters)
    end

    it "passes convert_boolean_return as true if it was specified as true in a guard parameter" do
      guard_parameters = { cwd: "/etc/chef", convert_boolean_return: true, architecture: :x86_64 }
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:block_from_attributes).with(
        { convert_boolean_return: true, code: "$true" }.merge(guard_parameters)
      ).and_return(Proc.new {})
      resource.only_if("$true", guard_parameters)
    end

    it "passes convert_boolean_return as false if it was specified as true in a guard parameter" do
      other_guard_parameters = { cwd: "/etc/chef", architecture: :x86_64 }
      parameters_with_boolean_disabled = other_guard_parameters.merge({ convert_boolean_return: false, code: "$true" })
      allow_any_instance_of(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:block_from_attributes).with(
        parameters_with_boolean_disabled
      ).and_return(Proc.new {})
      resource.only_if("$true", parameters_with_boolean_disabled)
    end
  end

  context "as a script running in Windows-based scripting language" do
    let(:windows_script_resource) { resource }
    let(:resource_instance_name ) { resource.command }
    let(:resource_name) { :powershell_script }
    let(:interpreter_file_name) { "powershell.exe" }

    it_behaves_like "a Windows script resource"
  end
end
