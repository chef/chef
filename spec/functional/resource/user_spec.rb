# encoding: UTF-8
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

  def etc_shadow
    File.open("/etc/shadow") {|f| f.read }
  end

  def supports_quote_in_username?
    OHAI_SYSTEM["platform_family"] == "debian"
  end

  before do
    # Silence shell_out live stream
    Chef::Log.level = :warn

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
      shell_out!("userdel", "-f", "-r", username, :returns => [0,12])
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
  let(:comment) { nil }

  let(:user_resource) do
    r = Chef::Resource::User.new("TEST USER RESOURCE", run_context)
    r.username(username)
    r.uid(uid)
    r.home(home)
    r.comment(comment)
    r.manage_home(manage_home)
    r.password(password)
    r.system(system)
    r
  end

  let(:skip) { false }

  describe "action :create" do

    context "when the user does not exist beforehand" do
      before do
        if reason = skip
          pending(reason)
        end
        user_resource.run_action(:create)
        user_resource.should be_updated_by_last_action
      end


      it "ensures the user exists" do
        pw_entry.name.should == username
      end

      #  On Debian, the only constraints are that usernames must neither start
      #  with a dash ('-') nor plus ('+') nor tilde ('~') nor contain a colon
      #  (':'), a comma (','), or a whitespace (space: ' ', end of line: '\n',
      #  tabulation: '\t', etc.). Note that using a slash ('/') may break the
      #  default algorithm for the definition of the user's home directory.

      context "and the username contains a single quote" do
        let(:skip) do
          if supports_quote_in_username?
            false
          else
            "Platform #{OHAI_SYSTEM["platform"]} not expected to support username w/ quote"
          end
        end

        let(:username) { "t'bilisi" }

        it "ensures the user exists" do
          pw_entry.name.should == username
        end
      end


      context "when uid is set" do
        # Should verify uid not in use...
        let(:uid) { 1999 }

        it "ensures the user has the given uid" do
          pw_entry.uid.should == "1999"
        end
      end

      context "when comment is set" do
        let(:comment) { "hello this is dog" }

        it "ensures the comment is set" do
          pw_entry.gecos.should == "hello this is dog"
        end

        context "in standard gecos format" do
          let(:comment) { "Bobo T. Clown,some building,555-555-5555,@boboclown" }

          it "ensures the comment is set" do
            pw_entry.gecos.should == comment
          end
        end

        context "to a string containing multibyte characters" do
          let(:comment) { "(╯°□°）╯︵ ┻━┻" }

          it "ensures the comment is set" do
            actual = pw_entry.gecos
            actual.force_encoding(Encoding::UTF_8) if "".respond_to?(:force_encoding)
            actual.should == comment
          end
        end

        context "to a string containing an apostrophe `'`" do
          let(:comment) { "don't go" }

          it "ensures the comment is set" do
            pw_entry.gecos.should == comment
          end
        end
      end

      context "when home is set" do
        let(:home) { "/home/#{username}" }

        it "ensures the user's home is set to the given path" do
          pw_entry.home.should == "/home/#{username}"
        end

        if OHAI_SYSTEM["platform_family"] == "rhel"
          # Inconsistent behavior. See: CHEF-2205
          it "creates the home dir when not explicitly asked to on RHEL (XXX)" do
            File.should exist("/home/#{username}")
          end
        else
          it "does not create the home dir without `manage_home'" do
            File.should_not exist("/home/#{username}")
          end
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
    end # when the user does not exist beforehand

    context "when the user already exists" do

      let(:expect_updated?) { true }

      let(:existing_uid) { nil }
      let(:existing_home) { nil }
      let(:existing_manage_home) { false }
      let(:existing_password) { nil }
      let(:existing_system) { false }
      let(:existing_comment) { nil }

      let(:existing_user) do
        r = Chef::Resource::User.new("TEST USER RESOURCE", run_context)
        # username is identity attr, must match.
        r.username(username)
        r.uid(existing_uid)
        r.home(existing_home)
        r.comment(existing_comment)
        r.manage_home(existing_manage_home)
        r.password(existing_password)
        r.system(existing_system)
        r
      end

      before do
        if reason = skip
          pending(reason)
        end
        existing_user.run_action(:create)
        existing_user.should be_updated_by_last_action
        user_resource.run_action(:create)
        user_resource.updated_by_last_action?.should == expect_updated?
      end

      context "and all properties are in the desired state" do
        let(:uid) { 1999 }
        let(:home) { "/home/bobo" }
        let(:manage_home) { true }
        # openssl passwd -1 "secretpassword"
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }
        let(:system) { false }
        let(:comment) { "hello this is dog" }

        let(:existing_uid) { uid }
        let(:existing_home) { home }
        let(:existing_manage_home) { manage_home }
        let(:existing_password) { password }
        let(:existing_system) { false }
        let(:existing_comment) { comment }

        let(:expect_updated?) { false }

        it "does not update the user" do
          user_resource.should_not be_updated
        end
      end

      context "and the uid is updated" do
        let(:uid) { 1999 }
        let(:existing_uid) { 1998 }

        it "ensures the uid is set to the desired value" do
          pw_entry.uid.should == "1999"
        end
      end

      context "and the comment is updated" do
        let(:comment) { "hello this is dog" }
        let(:existing_comment) { "woof" }

        it "ensures the comment field is set to the desired value" do
          pw_entry.gecos.should == "hello this is dog"
        end
      end

      context "and home directory is updated" do
        let(:existing_home) { "/home/foo" }
        let(:home) { "/home/bar" }
        it "ensures the home directory is set to the desired value" do
          pw_entry.home.should == "/home/bar"
        end

        context "and manage_home is enabled" do
          let(:existing_manage_home) { true }
          let(:manage_home) { true }
          it "moves the home directory to the new location" do
            File.should_not exist("/home/foo")
            File.should exist("/home/bar")
          end
        end

        context "and manage_home wasn't enabled but is now" do
          let(:existing_manage_home) { false }
          let(:manage_home) { true }

          if OHAI_SYSTEM["platform_family"] == "rhel"
            # Inconsistent behavior. See: CHEF-2205
            it "created the home dir b/c of CHEF-2205 so it still exists" do
              # This behavior seems contrary to expectation and non-convergent.
              File.should_not exist("/home/foo")
              File.should exist("/home/bar")
            end
          else
            it "does not create the home dir in the desired location (XXX)" do
              # This behavior seems contrary to expectation and non-convergent.
              File.should_not exist("/home/foo")
              File.should_not exist("/home/bar")
            end
          end
        end

        context "and manage_home was enabled but is not now" do
          let(:existing_manage_home) { true }
          let(:manage_home) { false }

          it "leaves the old home directory around (XXX)" do
            # Would it be better to remove the old home?
            File.should exist("/home/foo")
            File.should_not exist("/home/bar")
          end
        end
      end

      context "and a password is added" do
        # openssl passwd -1 "secretpassword"
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }

        it "ensures the password is set" do
          pw_entry.passwd.should == "x"
          expected_shadow = "chef-functional-test:$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          etc_shadow.should include(expected_shadow)
        end

      end

      context "and the password is updated" do
        # openssl passwd -1 "OLDpassword"
        let(:existing_password) { "$1$1dVmwm4z$CftsFn8eBDjDRUytYKkXB." }
        # openssl passwd -1 "secretpassword"
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }

        it "ensures the password is set to the desired value" do
          pw_entry.passwd.should == "x"
          expected_shadow = "chef-functional-test:$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          etc_shadow.should include(expected_shadow)
        end
      end

      context "and the user is changed from not-system to system" do
        let(:existing_system) { false }
        let(:system) { true }

        let(:expect_updated?) { false }

        it "does not modify the user at all" do
        end
      end

      context "and the user is changed from system to not-system" do
        let(:existing_system) { true }
        let(:system) { false }

        let(:expect_updated?) { false }

        it "does not modify the user at all" do
        end
      end

    end # when the user already exists
  end # action :create

  shared_context "user exists for lock/unlock" do
    let(:user_locked_context?) { false }

    def shadow_entry
      etc_shadow.lines.select {|l| l.include?(username) }.first
    end

    def shadow_password
      shadow_entry.split(':')[1]
    end

    before do
      # create user and setup locked/unlocked state
      user_resource.dup.run_action(:create)

      if user_locked_context?
        shell_out!("usermod -L #{username}")
        shadow_password.should include("!")
      elsif password
        shadow_password.should_not include("!")
      end
    end
  end

  describe "action :lock" do
    context "when the user does not exist" do
      it "raises a sensible error" do
        expect { user_resource.run_action(:lock) }.to raise_error(Chef::Exceptions::User)
      end
    end

    context "when the user exists" do

      include_context "user exists for lock/unlock"

      before do
        user_resource.run_action(:lock)
      end

      context "and the user is not locked" do
        # user will be locked if it has no password
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }

        it "locks the user's password" do
          shadow_password.should include("!")
        end
      end

      context "and the user is locked" do
        # user will be locked if it has no password
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }
        let(:user_locked_context?) { true }
        it "does not update the user" do
          user_resource.should_not be_updated_by_last_action
        end
      end
    end
  end # action :lock

  describe "action :unlock" do
    context "when the user does not exist" do
      it "raises a sensible error" do
        expect { user_resource.run_action(:unlock) }.to raise_error(Chef::Exceptions::User)
      end
    end

    context "when the user exists" do

      include_context "user exists for lock/unlock"

      before do
        begin
          user_resource.run_action(:unlock)
          @error = nil
        rescue Exception => e
          @error = e
        end
      end

      context "and has no password" do

        # TODO: platform_family should be setup in spec_helper w/ tags
        if OHAI_SYSTEM["platform_family"] == "suse"
          # suse gets this right:
          it "errors out trying to unlock the user" do
            @error.should be_a(Mixlib::ShellOut::ShellCommandFailed)
            @error.message.should include("Cannot unlock the password")
          end
        else

          # borked on all other platforms:
          it "is marked as updated but doesn't modify the user (XXX)" do
            # This should be an error instead; note that usermod still exits 0
            # (which is probably why this case silently fails):
            #
            # DEBUG: ---- Begin output of usermod -U chef-functional-test ----
            # DEBUG: STDOUT:
            # DEBUG: STDERR: usermod: unlocking the user's password would result in a passwordless account.
            # You should set a password with usermod -p to unlock this user's password.
            # DEBUG: ---- End output of usermod -U chef-functional-test ----
            # DEBUG: Ran usermod -U chef-functional-test returned 0
            @error.should be_nil
            pw_entry.passwd.should == 'x'
            shadow_password.should == "!"
          end
        end
      end

      context "and has a password" do
        let(:password) { "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/" }
        context "and the user is not locked" do
          it "does not update the user" do
            user_resource.should_not be_updated_by_last_action
          end
        end

        context "and the user is locked" do
          let(:user_locked_context?) { true }

          it "unlocks the user's password" do
            shadow_entry = etc_shadow.lines.select {|l| l.include?(username) }.first
            shadow_password = shadow_entry.split(':')[1]
            shadow_password.should_not include("!")
          end
        end
      end
    end
  end # action :unlock

end
