#
# Author:: Adam Edwards (<adamed@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/json_compat"
require File.expand_path("../../../../spec_helper", __FILE__)

describe Chef::Util::Powershell::Cmdlet, :windows_powershell_dsc_only do
  before(:all) do
    @node = Chef::Node.new
    @node.consume_external_attrs(OHAI_SYSTEM.data, {})
  end
  let(:cmd_output_format) { :text }
  let(:simple_cmdlet) { Chef::Util::Powershell::Cmdlet.new(@node, "get-childitem", cmd_output_format, { :depth => 2 }) }
  let(:invalid_cmdlet) { Chef::Util::Powershell::Cmdlet.new(@node, "get-idontexist", cmd_output_format) }
  let(:cmdlet_get_item_requires_switch_or_argument) { Chef::Util::Powershell::Cmdlet.new(@node, "get-item", cmd_output_format, { :depth => 2 }) }
  let(:cmdlet_alias_requires_switch_or_argument) { Chef::Util::Powershell::Cmdlet.new(@node, "alias", cmd_output_format, { :depth => 2 }) }
  let(:etc_directory) { "#{ENV['systemroot']}\\system32\\drivers\\etc" }
  let(:architecture_cmdlet) { Chef::Util::Powershell::Cmdlet.new(@node, "$env:PROCESSOR_ARCHITECTURE") }

  it "executes a simple process" do
    result = simple_cmdlet.run
    expect(result.succeeded?).to eq(true)
  end

  it "#run does not raise a PowershellCmdletException exception if the command cannot be executed" do
    expect { invalid_cmdlet.run }.not_to raise_error
  end

  it "#run! raises a PowershellCmdletException exception if the command cannot be executed" do
    expect { invalid_cmdlet.run! }.to raise_error(Chef::Exceptions::PowershellCmdletException)
  end

  it "executes a 64-bit command on a 64-bit OS, 32-bit otherwise" do
    os_arch = ENV["PROCESSOR_ARCHITEW6432"]
    if os_arch.nil?
      os_arch = ENV["PROCESSOR_ARCHITECTURE"]
    end

    result = architecture_cmdlet.run
    execution_arch = result.return_value
    execution_arch.strip!
    expect(execution_arch).to eq(os_arch)
  end

  it "passes command line switches to the command" do
    result = cmdlet_alias_requires_switch_or_argument.run({ :name => "ls" })
    expect(result.succeeded?).to eq(true)
  end

  it "passes command line arguments to the command" do
    result = cmdlet_alias_requires_switch_or_argument.run({}, {}, "ls")
    expect(result.succeeded?).to eq(true)
  end

  it "passes command line arguments and switches to the command" do
    result = cmdlet_get_item_requires_switch_or_argument.run({ :path => etc_directory }, {}, " | select-object -property fullname | format-table -hidetableheaders")
    expect(result.succeeded?).to eq(true)
    returned_directory = result.return_value
    returned_directory.strip!
    expect(returned_directory).to eq(etc_directory)
  end

  it "passes execution options to the command" do
    result = cmdlet_get_item_requires_switch_or_argument.run({}, { :cwd => etc_directory }, ". | select-object -property fullname | format-table -hidetableheaders")
    expect(result.succeeded?).to eq(true)
    returned_directory = result.return_value
    returned_directory.strip!
    expect(returned_directory).to eq(etc_directory)
  end

  context "when returning json" do
    let(:cmd_output_format) { :json }
    it "returns json format data" do
      result = cmdlet_alias_requires_switch_or_argument.run({}, {}, "ls")
      expect(result.succeeded?).to eq(true)
      expect(lambda { Chef::JSONCompat.parse(result.return_value) }).not_to raise_error
    end
  end

  context "when returning Ruby objects" do
    let(:cmd_output_format) { :object }
    it "returns object format data" do
      result = simple_cmdlet.run({}, { :cwd => etc_directory }, "hosts")
      expect(result.succeeded?).to eq(true)
      data = result.return_value
      expect(data["Name"]).to eq("hosts")
    end
  end

  context "when constructor is given invalid arguments" do
    let(:cmd_output_format) { :invalid }
    it "throws an exception if an invalid format is passed to the constructor" do
      expect(lambda { simple_cmdlet }).to raise_error(ArgumentError)
    end
  end
end
