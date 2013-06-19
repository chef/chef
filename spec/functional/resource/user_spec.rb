#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'spec_helper'
require 'chef/mixin/shell_out'

describe Chef::Resource::User, :unix_only, :requires_root do

  include Chef::Mixin::ShellOut

  # User provider is platform-dependent, we need platform ohai data:
  OHAI_SYSTEM = Ohai::System.new
  OHAI_SYSTEM.require_plugin("os")
  OHAI_SYSTEM.require_plugin("platform")


  # Utility code for /etc/passwd interaction, avoid any caching of user records:
  PwEntry = Struct.new(:name, :passwd, :uid, :gid, :gecos, :home, :shell)

  class UserNotFound < StandardError; end

  def pw_entry
    passwd_file = File.open("/etc/passwd", "rb") {|f| f.read}
    matcher = /^#{Regexp.escape(username)}.+$/
    if passwd_entry = passwd_file.scan(matcher).first
      PwEntry.new(*passwd_entry.split(':'))
    else
      raise UserNotFound, "no entry matching #{matcher.inspect} found in /etc/passwd"
    end
  end


  before do
    # Tests only implemented for a subset of platforms currently.
    user_provider = Chef::Platform.find_provider(OHAI_SYSTEM["platform"],
                                                 OHAI_SYSTEM["platform_version"],
                                                 :user)
    unless user_provider == Chef::Provider::User::Useradd
      pending "Only the useradd provider is supported at this time"
    end
  end

  after do
    begin
      pw_entry # will raise if the user doesn't exist
      shell_out!("userdel -f -r #{username}")
    rescue UserNotFound
      # nothing to remove
    end
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
    "chef-functional-test"
  end

  let(:uid) { nil }
  let(:home) { nil }
  let(:manage_home) { false }
  let(:password) { nil }
  let(:system) { false }

  let(:user_resource) do
    r = Chef::Resource::User.new("TEST USER RESOURCE", run_context)
    r.username(username)
    r.uid(uid)
    r.home(home)
    r.manage_home(manage_home)
    r.password(password)
    r.system(system)
    r
  end


  describe "action :create" do

    before do
      user_resource.run_action(:create)
    end

    context "when the user does not exist beforehand" do

      it "ensures the user exists" do
        pw_entry.name.should == username
      end

      context "when uid is set" do
        # Should verify uid not in use...
        let(:uid) { 1999 }

        it "ensures the user has the given uid" do
          pw_entry.uid.should == "1999"
        end
      end

      context "when home is set" do
        let(:home) { "/home/#{username}" }

        it "ensures the user's home is set to the given path" do
          pw_entry.home.should == "/home/#{username}"
        end

        it "does not create the home dir without `manage_home'" do
          File.should_not exist("/home/#{username}")
        end

        context "and manage_home is enabled" do
          let(:manage_home) { true }

          it "ensures the user's home directory exists" do
            File.should exist("/home/#{username}")
          end
        end
      end

      context "when a password is specified" do
        # openssl passwd -1 "secretpassword"
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }
        it "sets the user's shadow password" do
          pw_entry.passwd.should == "x"
          etc_shadow = File.open("/etc/shadow") {|f| f.read }
          expected_shadow = "chef-functional-test:$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          etc_shadow.should include(expected_shadow)
        end
      end

      context "when a system user is specified" do
        let(:system) { true }
        let(:uid_min) do
          # from `man useradd`, login user means uid will be between
          # UID_SYS_MIN and UID_SYS_MAX defined in /etc/login.defs. On my
          # Ubuntu 13.04 system, these are commented out, so we'll look at
          # UID_MIN to find the lower limit of the non-system-user range, and
          # use that value in our assertions.
          login_defs = File.open("/etc/login.defs", "rb") {|f| f.read }
          uid_min_scan = /^UID_MIN\s+(\d+)/
          login_defs.match(uid_min_scan)[1]
        end

        it "ensures the user has the properties of a system user" do
          pw_entry.uid.to_i.should be < uid_min.to_i
        end
      end
    end
  end
end
