#
# Author:: Bryan McLellan <btm@loftninjas.org>
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


describe "Chef::Platform#supports_dsc_invoke_resource?" :windows_only do
  it "returns false if powershell is not present" do
    node = Chef::Node.new
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
  end

  ["1.0", "2.0", "3.0", "4.0", "5.0.10017.9"].each do |version|
    it "returns false for PowerShell #{version}" do
      node = Chef::Node.new
      node.automatic[:languages][:powershell][:version] = version
      expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_falsey
    end
  end

  it "returns true for Powershell 5.0.10018.0" do
    node = Chef::Node.new
    node.automatic[:languages][:powershell][:version] = "5.0.10018.0"
    expect(Chef::Platform.supports_dsc_invoke_resource?(node)).to be_truthy
  end
end

describe "Chef::Platform#dsc_refresh_mode_disabled?" do
  let(:node) { instance_double("Chef::Node") }
  let(:powershell) { Class.new { include Chef_PowerShell::ChefPowerShell::PowerShellExec } }
  subject(:object) { powershell.new }

  it "returns true when RefreshMode is Disabled" do
    execution = object.powershell_exec("Get-DscLocalConfigurationManager", :powershell, timeout: -1)
    expect(execution.result["RefreshMode"]).to eq "PUSH"
    expect(Chef::Platform.dsc_refresh_mode_disabled?(node)).to be false
  end
end
