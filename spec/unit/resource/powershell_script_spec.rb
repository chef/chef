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

  it "inherits exactly the :cwd, :domain, :environment, :group, :password, :path, :user, :umask, :architecture, :elevated, :interpreter, :login properties from a parent resource class" do
    inherited_difference = Chef::Resource::PowershellScript.guard_inherited_attributes -
      %i{cwd domain environment group password path user umask architecture elevated interpreter login}

    expect(inherited_difference).to eq([])
  end

  context "as a script running in Windows-based scripting language" do
    let(:windows_script_resource) { resource }
    let(:resource_instance_name ) { resource.command }
    let(:resource_name) { :powershell_script }
    let(:interpreter_file_name) { "powershell.exe" }

    it_behaves_like "a Windows script resource"
  end
end
