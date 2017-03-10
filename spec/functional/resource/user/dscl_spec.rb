#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
  :mac_osx_only => true,
  :requires_root => true,
  :not_supported_on_mac_osx_106 => true,
}

describe "Chef::Resource::User with Chef::Provider::User::Dscl provider", metadata do
  include Chef::Mixin::ShellOut

  def clean_user
    shell_out!("/usr/bin/dscl . -delete '/Users/#{username}'")
  rescue Mixlib::ShellOut::ShellCommandFailed
      # Raised when the user is already cleaned
  end

  def user_should_exist
    expect(shell_out("/usr/bin/dscl . -ls /Users").stdout).to include username
  end

  def check_password(pass)
    # In order to test the password we use dscl passwd command since
    # that's the only command that gets the user password from CLI.
    expect(shell_out("dscl . -passwd /Users/greatchef #{pass} new_password").exitstatus).to eq(0)
    # Now reset the password back
    expect(shell_out("dscl . -passwd /Users/greatchef new_password #{pass}").exitstatus).to eq(0)
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
  let(:gid) { 20 }
  let(:home) { nil }
  let(:manage_home) { false }
  let(:password) { "XXXYYYZZZ" }
  let(:comment) { "Great Chef" }
  let(:shell) { "/bin/bash" }
  let(:salt) { nil }
  let(:iterations) { nil }

  let(:user_resource) do
    r = Chef::Resource::User::DsclUser.new("TEST USER RESOURCE", run_context)
    r.username(username)
    r.uid(uid)
    r.gid(gid)
    r.home(home)
    r.shell(shell)
    r.comment(comment)
    r.manage_home(manage_home)
    r.password(password)
    r.salt(salt)
    r.iterations(iterations)
    r
  end

  before do
    clean_user
  end

  after(:each) do
    clean_user
  end

  describe "action :create" do
    it "should create the user" do
      user_resource.run_action(:create)
      user_should_exist
      check_password(password)
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
        check_password("mykitchen")
      end
    end
  end

  describe "when password is being set via shadow hash" do
    let(:password) do
      if node[:platform_version].start_with?("10.7.")
        # On Mac 10.7 we only need to set the password
        "c9b3bd1a0cde797eef0eff16c580dab996ba3a21961cccc\
d0f5e65c61558243e50b1a490088bd4824e3b35562d383ca02260398\
ef1979b302212ec1c5383d1d05fc8d843"
      else
        "c734b6e4787c3727bb35e29fdd92b97c\
1de12df509577a045728255ec7c6c5f5\
c18efa05ed02b682ffa7ebc05119900e\
b1d4880833aa7a190afc13e2bf0936b8\
20123e8c98f0f9bcac2a629d9163caac\
9464a8c234f3919082400b4f939bb77b\
c5adbbac718b7eb99463a7b679571e0f\
1c9fef2ef08d0b9e9c2bcf644eed2ffc"
      end
    end

    let(:iterations) { 25000 }
    let(:salt) { "9e2e7d5ee473b496fd24cf0bbfcaedfcb291ee21740e570d1e917e874f8788ca" }

    it "action :create should create the user" do
      user_resource.run_action(:create)
      user_should_exist
      check_password("soawesome")
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
          check_password("mykitchen")
        end
      end
    end
  end

  describe "when a user is member of some groups" do
    let(:groups) { %w{staff operator} }

    before do
      existing_resource = user_resource.dup
      existing_resource.run_action(:create)

      groups.each do |group|
        shell_out!("/usr/bin/dscl . -append '/Groups/#{group}' GroupMembership #{username}")
      end
    end

    after do
      groups.each do |group|
        # Do not raise an error when user is correctly removed
        shell_out("/usr/bin/dscl . -delete '/Groups/#{group}' GroupMembership #{username}")
      end
    end

    it ":remove action removes the user from the groups and deletes the user" do
      user_resource.run_action(:remove)
      groups.each do |group|
        # Do not raise an error when group is empty
        expect(shell_out("dscl . read /Groups/staff GroupMembership").stdout).not_to include(group)
      end
    end
  end

end
