#
# Author:: Vasundhara Jagdale (<vasundhara.jagdale@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "spec_helper"

describe Chef::Resource::WindowsUserPrivilege, :windows_only do
  let(:principal) { nil }
  let(:privilege) { nil }
  let(:users) { nil }
  let(:sensitive) { true }

  let(:windows_test_run_context) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
    node.automatic["os"] = "windows"
    node.automatic["platform"] = "windows"
    node.automatic["platform_version"] = "6.1"
    node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end

  subject do
    new_resource = Chef::Resource::WindowsUserPrivilege.new(principal, windows_test_run_context)
    new_resource.privilege = privilege
    new_resource.principal = principal
    new_resource.users = users
    new_resource
  end

  describe "#add privilege" do
    after { subject.run_action(:remove) }

    context "when privilege is passed as string" do
      let(:principal) { "Administrator" }
      let(:privilege) { "SeCreateSymbolicLinkPrivilege" }

      it "adds user to privilege" do
        # Removing so that add update happens
        subject.run_action(:remove)
        subject.run_action(:add)
        expect(subject).to be_updated_by_last_action
      end

      it "is idempotent" do
        subject.run_action(:add)
        subject.run_action(:add)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "when privilege is passed as array" do
      let(:principal) { "Administrator" }
      let(:privilege) { %w{SeCreateSymbolicLinkPrivilege SeCreatePagefilePrivilege} }

      it "adds user to privilege" do
        subject.run_action(:add)
        expect(subject).to be_updated_by_last_action
      end

      it "is idempotent" do
        subject.run_action(:add)
        subject.run_action(:add)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  describe "#set privilege" do
    after { remove_user_privilege("Administrator", subject.privilege) }

    let(:principal) { "user_privilege" }
    let(:users) { %w{Administrators Administrator} }
    let(:privilege) { %w{SeCreateSymbolicLinkPrivilege} }

    it "sets user to privilege" do
      subject.action(:set)
      subject.run_action(:set)
      expect(subject).to be_updated_by_last_action
    end

    it "is idempotent" do
      subject.action(:set)
      subject.run_action(:set)
      subject.run_action(:set)
      expect(subject).not_to be_updated_by_last_action
    end

    it "raise error if users not provided" do
      subject.users = nil
      subject.action(:set)
      expect { subject.run_action(:set) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "#remove privilege" do
    let(:principal) { "Administrator" }
    context "when privilege is passed as array" do
      let(:privilege) { "SeCreateSymbolicLinkPrivilege" }
      it "remove user from privilege" do
        subject.run_action(:add)
        subject.run_action(:remove)
        expect(subject).to be_updated_by_last_action
      end

      it "is idempotent" do
        subject.run_action(:add)
        subject.run_action(:remove)
        subject.run_action(:remove)
        expect(subject).not_to be_updated_by_last_action
      end
    end

    context "when privilege is passed as array" do
      let(:privilege) { %w{SeCreateSymbolicLinkPrivilege SeCreatePagefilePrivilege} }
      it "remove user from privilege" do
        subject.run_action(:add)
        subject.run_action(:remove)
        expect(subject).to be_updated_by_last_action
      end

      it "is idempotent" do
        subject.run_action(:add)
        subject.run_action(:remove)
        subject.run_action(:remove)
        expect(subject).not_to be_updated_by_last_action
      end
    end
  end

  describe "running with non admin user" do
    include Chef::Mixin::UserContext

    let(:user) { "security_user" }
    let(:password) { "Security@123" }
    let(:principal) { "user_privilege" }
    let(:users) { ["Administrators", "#{domain}\\security_user"] }
    let(:privilege) { %w{SeCreateSymbolicLinkPrivilege} }

    let(:domain) do
      ENV["COMPUTERNAME"]
    end

    before do
      allow_any_instance_of(Chef::Mixin::UserContext).to receive(:node).and_return({ "platform_family" => "windows" })
      add_user = Mixlib::ShellOut.new("net user #{user} #{password} /ADD")
      add_user.run_command
      add_user.error!
    end

    after do
      remove_user_privilege("#{domain}\\#{user}", subject.privilege)
      delete_user = Mixlib::ShellOut.new("net user #{user} /delete")
      delete_user.run_command
      delete_user.error!
    end

    it "sets user to privilege" do
      subject.action(:set)
      subject.run_action(:set)
      expect(subject).to be_updated_by_last_action
    end

    it "is idempotent" do
      subject.action(:set)
      subject.run_action(:set)
      subject.run_action(:set)
      expect(subject).not_to be_updated_by_last_action
    end
  end

  def remove_user_privilege(user, privilege)
    subject.action(:remove)
    subject.principal = user
    subject.privilege = privilege
    subject.run_action(:remove)
  end
end
