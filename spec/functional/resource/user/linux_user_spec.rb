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

metadata = {
  requires_root: true,
  linux_only: true,
}

describe "Chef::Resource::User with Chef::Provider::User::LinuxUser provider", metadata do
  include Chef::Mixin::ShellOut

  def clean_user
    shell_out!("/usr/sbin/userdel #{username}")
  rescue Mixlib::ShellOut::ShellCommandFailed
    # Raised when the user is already cleaned
  end

  def ensure_file_cache_path_exists
    path = Chef::Config["file_cache_path"]
    FileUtils.mkdir_p(path) unless File.directory?(path)
  end

  def user_should_exist
    expect(shell_out("grep -q #{username} /etc/passwd").error?).to be(false)
  end

  def check_password(pass, user)
    expect(shell_out("grep ^#{user}: /etc/shadow | cut -d: -f2 | grep ^#{pass}$").exitstatus).to eq(0)
  end

  let(:node) do
    n = Chef::Node.new
    n.consume_external_attrs(OHAI_SYSTEM.data.dup, {})
    n
  end

  let(:events) do
    Chef::EventDispatch::Dispatcher.new
  end

  let(:run_context) do
    Chef::RunContext.new(node, {}, events)
  end

  let(:username) do
    "greatchef"
  end

  let(:uid) { nil }
  let(:gid) do
    # SLES 15 doesn't have the "20" group and
    # so lets just pick the last group... no,
    # Etc.group.map(&:gid).last does not work
    Etc.enum_for(:group).map(&:gid).last
  end
  let(:home) { nil }
  let(:manage_home) { false }
  let(:password) { "XXXYYYZZZ" }
  let(:comment) { "Great Chef" }
  let(:shell) { "/bin/bash" }
  let(:salt) { nil }

  let(:user_resource) do
    r = Chef::Resource::User::LinuxUser.new("TEST USER RESOURCE", run_context)
    r.username(username)
    r.uid(uid)
    r.gid(gid)

    r.home(home)
    r.shell(shell)
    r.comment(comment)
    r.manage_home(manage_home)
    r.password(password)
    r.salt(salt)
    r
  end

  before do
    clean_user
    ensure_file_cache_path_exists
  end

  after(:each) do
    clean_user
  end

  describe "action :create" do
    it "should create the user" do
      user_resource.run_action(:create)
      user_should_exist
      check_password(password, username)
    end
  end

  describe "when user exists" do
    before do
      existing_resource = user_resource.dup
      existing_resource.run_action(:create)
      user_should_exist
    end

    describe "when password is updated" do
      it "should update the password of the user" do
        user_resource.password("mykitchen")
        user_resource.run_action(:create)
        check_password("mykitchen", username)
      end
    end
  end
end
