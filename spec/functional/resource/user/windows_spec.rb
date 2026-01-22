# Author:: Jay Mundrawala (<jdm@chef.io>)
# Author:: Stuart Preston (<stuart@chef.io>)
#
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
require "chef/mixin/shell_out"

describe Chef::Provider::User::Windows, :windows_only do
  include Chef::Mixin::ShellOut

  let(:username) { "ChefFunctionalTest" }
  let(:password) { "DummyP2ssw0rd!" }

  let(:node) do
    n = Chef::Node.new
    n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    n
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:logger) { double("Mixlib::Log::Child").as_null_object }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::User::WindowsUser.new(username, run_context).tap do |r|
      r.provider(Chef::Provider::User::Windows)
      r.password(password)
    end
  end

  def delete_user(u)
    shell_out("net user #{u} /delete")
  end

  def backup_secedit_policy
    backup_command = "secedit /export /cfg #{ENV["TEMP"]}\\secedit_restore.inf /areas SECURITYPOLICY"
    shell_out(backup_command)
  end

  def restore_secedit_policy
    security_database = "C:\\windows\\security\\database\\seceditnew.sdb"
    restore_command = "secedit /configure /db #{security_database} /cfg #{ENV["TEMP"]}\\secedit_restore.inf /areas SECURITYPOLICY"
    shell_out(restore_command)
  end

  def set_windows_minimum_password_length(minimum_password_length = 0)
    require "tempfile"
    temp_security_database = "C:\\windows\\security\\database\\seceditnew.sdb"
    temp_security_template = Tempfile.new(["chefpolicy", ".inf"])
    file_content = <<~EOF
      [Unicode]
      Unicode=yes
      [System Access]
      MinimumPasswordLength = #{minimum_password_length}
      PasswordComplexity = 0
      [Version]
      signature="$CHICAGO$"
      Revision=1
    EOF
    windows_template_path = temp_security_template.path.gsub("/") { "\\" }
    security_command = "secedit /configure /db #{temp_security_database} /cfg #{windows_template_path} /areas SECURITYPOLICY"
    temp_security_template.write(file_content)
    temp_security_template.close
    shell_out(security_command)
  end

  before(:all) do
    backup_secedit_policy
  end

  before(:each) do
    delete_user(username)
    allow(run_context).to receive(:logger).and_return(logger)
  end

  after(:all) do
    restore_secedit_policy
  end

  describe "action :create" do
    context "on a Windows system with a policy that requires non-blank passwords and no complexity requirements" do

      before(:all) do
        set_windows_minimum_password_length(1)
      end

      context "when a username and non-empty password are given" do
        it "creates a user" do
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
          expect(shell_out("net user #{username}").exitstatus).to eq(0)
        end

        it "is idempotent" do
          new_resource.run_action(:create)
          new_resource.run_action(:create)
          expect(new_resource).not_to be_updated_by_last_action
        end

        it "allows changing the password" do
          new_resource.run_action(:create)
          new_resource.password(SecureRandom.uuid)
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
        end
      end

      context "when a username and empty password are given" do
        it "does not create the specified user" do
          new_resource.password("")
          expect { new_resource.run_action(:create) }.to raise_exception(Chef::Exceptions::Win32APIError, /The password does not meet the password policy requirements/)
        end
      end
    end

    context "on a Windows system with a policy that allows blank passwords" do

      before(:all) do
        set_windows_minimum_password_length(0)
      end

      context "when a username and non-empty password are given" do
        it "creates a user" do
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
          expect(shell_out("net user #{username}").exitstatus).to eq(0)
        end

        it "is idempotent" do
          new_resource.run_action(:create)
          new_resource.run_action(:create)
          expect(new_resource).not_to be_updated_by_last_action
        end

        it "allows changing the password" do
          new_resource.run_action(:create)
          new_resource.password(SecureRandom.uuid)
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
        end
      end

      context "when a username and empty password are given" do
        it "creates a user" do
          new_resource.password("")
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
          expect(shell_out("net user #{username}").exitstatus).to eq(0)
        end

        it "is idempotent" do
          new_resource.password("")
          new_resource.run_action(:create)
          new_resource.run_action(:create)
          expect(new_resource).not_to be_updated_by_last_action
        end

        it "allows changing the password from empty to a value" do
          new_resource.password("")
          new_resource.run_action(:create)
          new_resource.password(SecureRandom.uuid)
          new_resource.run_action(:create)
          expect(new_resource).to be_updated_by_last_action
        end
      end
    end

    context "with a gid specified" do
      it "warns unsupported" do
        expect(logger).to receive(:warn).with(/not implemented/)
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
