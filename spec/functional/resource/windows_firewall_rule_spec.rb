#
# Author:: Matt Wrock (<matt@mattwrock.com>)
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
require "chef/mixin/powershell_exec"

describe Chef::Resource::WindowsFirewallRule, :windows_only do
  include Chef::Mixin::PowershellExec

  let(:rule_name) { "fake_rule" }
  let(:remote_port) { "5555" }
  let(:enabled) { false }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::WindowsFirewallRule.new("test firewall rule", run_context)
    new_resource.rule_name rule_name
    new_resource.remote_port remote_port
    new_resource.enabled enabled
    new_resource
  end

  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end

  context "create a new rule" do
    after { delete_rule }

    it "creates the rule" do
      subject.run_action(:create)
      expect(get_installed_rule_name).to eq(rule_name)
      expect(get_installed_rule_remote_port).to eq(remote_port)
    end

    it "does not create rule if it already exists" do
      subject.run_action(:create)
      subject.run_action(:create)
      expect(subject).not_to be_updated_by_last_action
    end

    it "updates the rule if it changed" do
      subject.run_action(:create)
      subject.remote_port = "7777"
      subject.run_action(:create)
      expect(get_installed_rule_remote_port).to eq("7777")
    end
  end

  context "delete a rule" do
    it "deletes an existing rule" do
      subject.run_action(:create)
      subject.run_action(:delete)
      expect(get_installed_rule_name).to be_empty
    end

    it "does not delete rule if it does not exist" do
      subject.run_action(:delete)
      expect(subject).not_to be_updated_by_last_action
    end
  end

  def get_installed_rule_name
    powershell_exec!("(Get-NetFirewallRule -Name #{rule_name} -ErrorAction SilentlyContinue).Name").result
  end

  def get_installed_rule_remote_port
    powershell_exec!("((Get-NetFirewallRule -Name #{rule_name} -ErrorAction SilentlyContinue) | Get-NetFirewallPortFilter).RemotePort").result
  end

  def delete_rule
    rule_to_remove = Chef::Resource::WindowsFirewallRule.new(rule_name, run_context)
    rule_to_remove.run_action(:delete)
  end
end
