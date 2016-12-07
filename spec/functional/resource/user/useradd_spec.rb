# encoding: UTF-8
#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
require "functional/resource/base"
require "chef/mixin/shell_out"

def resource_for_platform(username, run_context)
  Chef::Resource.resource_for_node(:user, node).new(username, run_context)
end

# ideally we could somehow pass an array of [ ...::Aix, ...::Linux ] to the
# filter, but we have to pick the right one for the O/S.
def user_provider_filter
  case ohai[:os]
  when "aix"
    Chef::Provider::User::Aix
  when "linux"
    Chef::Provider::User::Linux
  end
end

metadata = {
  :unix_only => true,
  :requires_root => true,
  :not_supported_on_mac_osx => true,
  :provider => { :user => user_provider_filter },
}

describe Chef::Provider::User::Useradd, metadata do

  include Chef::Mixin::ShellOut

  # Utility code for /etc/passwd interaction, avoid any caching of user records:
  PwEntry = Struct.new(:name, :passwd, :uid, :gid, :gecos, :home, :shell)

  class UserNotFound < StandardError; end

  def pw_entry
    passwd_file = File.open("/etc/passwd", "rb") { |f| f.read }
    matcher = /^#{Regexp.escape(username)}.+$/
    if passwd_entry = passwd_file.scan(matcher).first
      PwEntry.new(*passwd_entry.split(":"))
    else
      raise UserNotFound, "no entry matching #{matcher.inspect} found in /etc/passwd"
    end
  end

  def etc_shadow
    case ohai[:platform]
    when "aix"
      File.open("/etc/security/passwd") { |f| f.read }
    else
      File.open("/etc/shadow") { |f| f.read }
    end
  end

  def self.quote_in_username_unsupported?
    if OHAI_SYSTEM["platform_family"] == "debian"
      false
    else
      "Only debian family systems support quotes in username"
    end
  end

  def password_should_be_set
    if ohai[:platform] == "aix"
      expect(pw_entry.passwd).to eq("!")
    else
      expect(pw_entry.passwd).to eq("x")
    end
  end

  def try_cleanup
    ["/home/cheftestfoo", "/home/cheftestbar", "/home/cf-test"].each do |f|
      FileUtils.rm_rf(f) if File.exists? f
    end

    ["cf-test"].each do |u|
      r = resource_for_platform("DELETE USER", run_context)
      r.manage_home true
      r.username("cf-test")
      r.run_action(:remove)
    end
  end

  before do
    # Silence shell_out live stream
    Chef::Log.level = :warn
    try_cleanup
  end

  after do
    max_retries = 3
    while max_retries > 0
      begin
        pw_entry # will raise if the user doesn't exist
        status = shell_out!("userdel", "-r", username, :returns => [0, 8, 12])

        # Error code 8 during userdel indicates that the user is logged in.
        # This occurs randomly because the accounts daemon holds a lock due to which userdel fails.
        # The work around is to retry userdel for 3 times.
        break if status.exitstatus != 8

        sleep 1
        max_retries -= 1
      rescue UserNotFound
        break
      end
    end

    status.error! if max_retries == 0
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

  let(:username) { "cf-test" }
  let(:uid) { nil }
  let(:home) { nil }
  let(:manage_home) { false }
  let(:password) { nil }
  let(:system) { false }
  let(:comment) { nil }

  let(:user_resource) do
    r = resource_for_platform("TEST USER RESOURCE", run_context)
    r.username(username)
    r.uid(uid)
    r.home(home)
    r.comment(comment)
    r.manage_home(manage_home)
    r.password(password)
    r.system(system)
    r
  end

  let(:expected_shadow) do
    if ohai[:platform] == "aix"
      expected_shadow = "cf-test" # For aix just check user entry in shadow file
    else
      expected_shadow = "cf-test:$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
    end
  end

  describe "action :create" do

    context "when the user does not exist beforehand" do
      before do
        user_resource.run_action(:create)
        expect(user_resource).to be_updated_by_last_action
      end

      it "ensures the user exists" do
        expect(pw_entry.name).to eq(username)
      end

      #  On Debian, the only constraints are that usernames must neither start
      #  with a dash ('-') nor plus ('+') nor tilde ('~') nor contain a colon
      #  (':'), a comma (','), or a whitespace (space: ' ', end of line: '\n',
      #  tabulation: '\t', etc.). Note that using a slash ('/') may break the
      #  default algorithm for the definition of the user's home directory.

      context "and the username contains a single quote", skip: quote_in_username_unsupported? do

        let(:username) { "t'bilisi" }

        it "ensures the user exists" do
          expect(pw_entry.name).to eq(username)
        end
      end

      context "when uid is set" do
        # Should verify uid not in use...
        let(:uid) { 1999 }

        it "ensures the user has the given uid" do
          expect(pw_entry.uid).to eq("1999")
        end
      end

      context "when comment is set" do
        let(:comment) { "hello this is dog" }

        it "ensures the comment is set" do
          expect(pw_entry.gecos).to eq("hello this is dog")
        end

        context "in standard gecos format" do
          let(:comment) { "Bobo T. Clown,some building,555-555-5555,@boboclown" }

          it "ensures the comment is set" do
            expect(pw_entry.gecos).to eq(comment)
          end
        end

        context "to a string containing multibyte characters" do
          let(:comment) { "(╯°□°）╯︵ ┻━┻" }

          it "ensures the comment is set" do
            actual = pw_entry.gecos
            actual.force_encoding(Encoding::UTF_8) if "".respond_to?(:force_encoding)
            expect(actual).to eq(comment)
          end
        end

        context "to a string containing an apostrophe `'`" do
          let(:comment) { "don't go" }

          it "ensures the comment is set" do
            expect(pw_entry.gecos).to eq(comment)
          end
        end
      end

      context "when home is set" do
        let(:home) { "/home/#{username}" }

        it "ensures the user's home is set to the given path" do
          expect(pw_entry.home).to eq(home)
        end

        it "does not create the home dir without `manage_home'" do
          expect(File).not_to exist(home)
        end

        context "and manage_home is enabled" do
          let(:manage_home) { true }

          it "ensures the user's home directory exists" do
            expect(File).to exist(home)
          end
        end

        context "and manage_home is the default" do
          let(:manage_home) { nil }

          it "does not create the home dir without `manage_home'" do
            expect(File).not_to exist(home)
          end
        end
      end

      context "when a password is specified" do
        # openssl passwd -1 "secretpassword"
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        it "sets the user's shadow password" do
          password_should_be_set
          expect(etc_shadow).to include(expected_shadow)
        end
      end

      context "when a system user is specified", skip: aix? do
        let(:system) { true }
        let(:uid_min) do
          # from `man useradd`, login user means uid will be between
          # UID_SYS_MIN and UID_SYS_MAX defined in /etc/login.defs. On my
          # Ubuntu 13.04 system, these are commented out, so we'll look at
          # UID_MIN to find the lower limit of the non-system-user range, and
          # use that value in our assertions.
          login_defs = File.open("/etc/login.defs", "rb") { |f| f.read }
          uid_min_scan = /^UID_MIN\s+(\d+)/
          login_defs.match(uid_min_scan)[1]
        end

        it "ensures the user has the properties of a system user" do
          expect(pw_entry.uid.to_i).to be < uid_min.to_i
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
        r = resource_for_platform("TEST USER RESOURCE", run_context)
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
          skip(reason)
        end
        existing_user.run_action(:create)
        expect(existing_user).to be_updated_by_last_action
        user_resource.run_action(:create)
        expect(user_resource.updated_by_last_action?).to eq(expect_updated?)
      end

      context "and all properties are in the desired state" do
        let(:uid) { 1999 }
        let(:home) { "/home/bobo" }
        let(:manage_home) { true }
        # openssl passwd -1 "secretpassword"
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

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
          expect(user_resource).not_to be_updated
        end
      end

      context "and the uid is updated" do
        let(:uid) { 1999 }
        let(:existing_uid) { 1998 }

        it "ensures the uid is set to the desired value" do
          expect(pw_entry.uid).to eq("1999")
        end
      end

      context "and the comment is updated" do
        let(:comment) { "hello this is dog" }
        let(:existing_comment) { "woof" }

        it "ensures the comment field is set to the desired value" do
          expect(pw_entry.gecos).to eq("hello this is dog")
        end
      end

      context "and home directory is updated" do
        let(:existing_home) { "/home/cheftestfoo" }
        let(:home) { "/home/cheftestbar" }
        it "ensures the home directory is set to the desired value" do
          expect(pw_entry.home).to eq("/home/cheftestbar")
        end

        context "and manage_home is enabled" do
          let(:existing_manage_home) { true }
          let(:manage_home) { true }
          it "moves the home directory to the new location" do
            expect(File).not_to exist("/home/cheftestfoo")
            expect(File).to exist("/home/cheftestbar")
          end
        end

        context "and manage_home wasn't enabled but is now" do
          let(:existing_manage_home) { false }
          let(:manage_home) { true }

          if %w{rhel fedora}.include?(OHAI_SYSTEM["platform_family"])
            # Inconsistent behavior. See: CHEF-2205
            it "created the home dir b/c of CHEF-2205 so it still exists" do
              # This behavior seems contrary to expectation and non-convergent.
              expect(File).not_to exist("/home/cheftestfoo")
              expect(File).to exist("/home/cheftestbar")
            end
          elsif ohai[:platform] == "aix"
            it "creates the home dir in the desired location" do
              expect(File).not_to exist("/home/cheftestfoo")
              expect(File).to exist("/home/cheftestbar")
            end
          else
            it "does not create the home dir in the desired location (XXX)" do
              # This behavior seems contrary to expectation and non-convergent.
              expect(File).not_to exist("/home/cheftestfoo")
              expect(File).not_to exist("/home/cheftestbar")
            end
          end
        end

        context "and manage_home was enabled but is not now" do
          let(:existing_manage_home) { true }
          let(:manage_home) { false }

          it "leaves the old home directory around (XXX)" do
            # Would it be better to remove the old home?
            expect(File).to exist("/home/cheftestfoo")
            expect(File).not_to exist("/home/cheftestbar")
          end
        end
      end

      context "and a password is added" do
        # openssl passwd -1 "secretpassword"
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        it "ensures the password is set" do
          password_should_be_set
          expect(etc_shadow).to include(expected_shadow)
        end

      end

      context "and the password is updated" do
        # openssl passwd -1 "OLDpassword"
        let(:existing_password) do
          case ohai[:platform]
          when "aix"
            "jkzG6MvUxjk2g"
          else
            "$1$1dVmwm4z$CftsFn8eBDjDRUytYKkXB."
          end
        end

        # openssl passwd -1 "secretpassword"
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        it "ensures the password is set to the desired value" do
          password_should_be_set
          expect(etc_shadow).to include(expected_shadow)
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
      etc_shadow.lines.find { |l| l.include?(username) }
    end

    def shadow_password
      shadow_entry.split(":")[1]
    end

    def aix_user_lock_status
      lock_info = shell_out!("lsuser -a account_locked #{username}")
      /\S+\s+account_locked=(\S+)/.match(lock_info.stdout)[1]
    end

    def user_account_should_be_locked
      case ohai[:platform]
      when "aix"
        expect(aix_user_lock_status).to eq("true")
      else
        expect(shadow_password).to include("!")
      end
    end

    def user_account_should_be_unlocked
      case ohai[:platform]
      when "aix"
        expect(aix_user_lock_status).to eq("false")
      else
        expect(shadow_password).not_to include("!")
      end
    end

    def lock_user_account
      case ohai[:platform]
      when "aix"
        shell_out!("chuser account_locked=true #{username}")
      else
        shell_out!("usermod -L #{username}")
      end
    end

    before do
      # create user and setup locked/unlocked state
      user_resource.dup.run_action(:create)

      if user_locked_context?
        lock_user_account
        user_account_should_be_locked
      elsif password
        user_account_should_be_unlocked
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
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        it "locks the user's password" do
          user_account_should_be_locked
        end
      end

      context "and the user is locked" do
        # user will be locked if it has no password
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        let(:user_locked_context?) { true }
        it "does not update the user" do
          expect(user_resource).not_to be_updated_by_last_action
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
        if %w{opensuse}.include?(OHAI_SYSTEM["platform_family"]) ||
            (%w{suse}.include?(OHAI_SYSTEM["platform_family"]) &&
            OHAI_SYSTEM["platform_version"].to_f < 12.1)
          # suse 11.x gets this right:
          it "errors out trying to unlock the user" do
            expect(@error).to be_a(Mixlib::ShellOut::ShellCommandFailed)
            expect(@error.message).to include("Cannot unlock the password")
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
            expect(@error).to be_nil
            if ohai[:platform] == "aix"
              expect(pw_entry.passwd).to eq("*")
              user_account_should_be_unlocked
            else
              expect(pw_entry.passwd).to eq("x")
              expect(shadow_password).to include("!")
            end
          end
        end
      end

      context "and has a password" do
        let(:password) do
          case ohai[:platform]
          when "aix"
            "eL5qfEVznSNss"
          else
            "$1$RRa/wMM/$XltKfoX5ffnexVF4dHZZf/"
          end
        end

        context "and the user is not locked" do
          it "does not update the user" do
            expect(user_resource).not_to be_updated_by_last_action
          end
        end

        context "and the user is locked" do
          let(:user_locked_context?) { true }

          it "unlocks the user's password" do
            user_account_should_be_unlocked
          end
        end
      end
    end
  end # action :unlock

end
