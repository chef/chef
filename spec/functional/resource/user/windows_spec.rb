# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software
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
require "chef/mixin/shell_out"

describe Chef::Provider::User::Windows, :windows_only do
  include Chef::Mixin::ShellOut

  let(:username) { "ChefFunctionalTest" }
  let(:password) { SecureRandom.uuid }

  let(:node) do
    n = Chef::Node.new
    n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    n
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::User.new(username, run_context).tap do |r|
      r.provider(Chef::Provider::User::Windows)
      r.password(password)
    end
  end

  def delete_user(u)
    shell_out("net user #{u} /delete")
  end

  before do
    delete_user(username)
  end

  describe "action :create" do
    it "creates a user when a username and password are given" do
      new_resource.run_action(:create)
      expect(new_resource).to be_updated_by_last_action
      expect(shell_out("net user #{username}").exitstatus).to eq(0)
    end

    it "reports no changes if there are no changes needed" do
      new_resource.run_action(:create)
      new_resource.run_action(:create)
      expect(new_resource).not_to be_updated_by_last_action
    end

    it "allows chaning the password" do
      new_resource.run_action(:create)
      new_resource.password(SecureRandom.uuid)
      new_resource.run_action(:create)
      expect(new_resource).to be_updated_by_last_action
    end

    context "with a gid specified" do
      it "warns unsupported" do
        expect(Chef::Log).to receive(:warn).with(/not implemented/)
        new_resource.gid("agroup")
        new_resource.run_action(:create)
      end
    end
  end

  describe "action :remove" do
    before do
      new_resource.run_action(:create)
    end

    it "deletes the user" do
      new_resource.run_action(:remove)
      expect(new_resource).to be_updated_by_last_action
      expect(shell_out("net user #{username}").exitstatus).to eq(2)
    end

    it "is idempotent" do
      new_resource.run_action(:remove)
      new_resource.run_action(:remove)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "action :lock" do
    before do
      new_resource.run_action(:create)
    end

    it "locks the user account" do
      new_resource.run_action(:lock)
      expect(new_resource).to be_updated_by_last_action
      expect(shell_out("net user #{username}").stdout).to match(/Account active\s*No/)
    end

    it "is idempotent" do
      new_resource.run_action(:lock)
      new_resource.run_action(:lock)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end

  describe "action :unlock" do
    before do
      new_resource.run_action(:create)
      new_resource.run_action(:lock)
    end

    it "unlocks the user account" do
      new_resource.run_action(:unlock)
      expect(new_resource).to be_updated_by_last_action
      expect(shell_out("net user #{username}").stdout).to match(/Account active\s*Yes/)
    end

    it "is idempotent" do
      new_resource.run_action(:unlock)
      new_resource.run_action(:unlock)
      expect(new_resource).not_to be_updated_by_last_action
    end
  end
end
