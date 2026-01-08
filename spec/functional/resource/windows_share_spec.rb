#
# Author:: Matt Wrock (<matt@mattwrock.com>)
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
require "spec_helper"
require "chef/mixin/powershell_exec"

describe Chef::Resource::WindowsShare, :windows_only do
  include Chef::Mixin::PowershellExec

  let(:share_name) { "fake_share" }
  let(:path) { ENV["temp"] }
  let(:concurrent_user_limit) { 7 }
  let(:full_users) { ["#{ENV["USERNAME"]}"] }

  let(:run_context) do
    node = Chef::Node.new
    node.default["hostname"] = ENV["COMPUTERNAME"]
    Chef::RunContext.new(node, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::WindowsShare.new("test windows share", run_context)
    new_resource.share_name share_name
    new_resource.path path
    new_resource.concurrent_user_limit concurrent_user_limit
    new_resource.full_users full_users
    new_resource
  end

  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end

  context "create a new share" do
    after { delete_share }

    it "creates the share" do
      subject.run_action(:create)
      share = get_installed_share
      expect(share["Name"]).to eq(share_name)
      expect(share["Path"]).to eq(path)
      expect(get_installed_share_access["AccountName"]).to eq("#{ENV["COMPUTERNAME"]}\\#{full_users[0]}")
    end

    it "does not create share if it already exists" do
      subject.run_action(:create)
      subject.run_action(:create)
      expect(subject).not_to be_updated_by_last_action
    end

    it "updates the share if it changed" do
      subject.run_action(:create)
      subject.concurrent_user_limit 8
      subject.full_users ["BUILTIN\\Administrators"]
      subject.run_action(:create)
      share = get_installed_share
      expect(share["ConcurrentUserLimit"]).to eq(8)
      expect(get_installed_share_access["AccountName"]).to eq("BUILTIN\\Administrators")
    end

  end

  context "delete a share" do
    it "deletes an existing share" do
      subject.run_action(:create)
      subject.run_action(:delete)
      expect(get_installed_share).to be_empty
    end

    it "does not delete share if it does not exist" do
      subject.run_action(:delete)
      expect(subject).not_to be_updated_by_last_action
    end
  end

  def get_installed_share
    powershell_exec!("Get-SmbShare -Name #{share_name} -ErrorAction SilentlyContinue").result
  end

  def get_installed_share_access
    powershell_exec!("Get-SmbShareAccess -Name #{share_name} -ErrorAction SilentlyContinue").result
  end

  def delete_share
    rule_to_remove = Chef::Resource::WindowsShare.new(share_name, run_context)
    rule_to_remove.run_action(:delete)
  end
end
