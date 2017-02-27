#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Author:: Dave Eddy (<dave@daveeddy.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
# Copyright:: Copyright 2015-2016, Dave Eddy
#
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

require "mixlib/shellout"
require "spec_helper"

describe Chef::Provider::User::Solaris do

  let(:shellcmdresult) do
    Struct.new(:stdout, :stderr, :exitstatus)
  end

  let(:node) do
    Chef::Node.new.tap do |node|
      node.automatic["platform"] = "solaris2"
    end
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:new_resource) do
    Chef::Resource::User::SolarisUser.new("adam", @run_context)
  end
  let(:current_resource) do
    Chef::Resource::User::SolarisUser.new("adam", @run_context)
  end

  subject(:provider) do
    described_class.new(new_resource, run_context).tap do |p|
      p.current_resource = current_resource
      # Prevent the useradd-based provider tests from trying to write /etc/shadow
      allow(p).to receive(:write_shadow_file)
    end
  end

  describe "when we want to set a password" do
    before(:each) do
      new_resource.password "hocus-pocus"
    end

    it "should use its own shadow file writer to set the password" do
      expect(provider).to receive(:write_shadow_file)
      allow(provider).to receive(:shell_out!).and_return(true)
      provider.manage_user
    end

    it "should write out a modified version of the password file" do
      # Let this test run #write_shadow_file
      allow(provider).to receive(:write_shadow_file).and_call_original
      password_file = Tempfile.new("shadow")
      password_file.puts "adam:existingpassword:15441::::::"
      password_file.close
      provider.password_file = password_file.path
      allow(provider).to receive(:shell_out!).and_return(true)
      # may not be able to write to /etc for tests...
      temp_file = Tempfile.new("shadow")
      allow(Tempfile).to receive(:new).with("shadow", "/etc").and_return(temp_file)
      new_resource.password "verysecurepassword"
      provider.manage_user
      expect(::File.open(password_file.path, "r").read).to match(/adam:verysecurepassword:/)
      password_file.unlink
    end
  end

  describe "#create_user" do
    context "with a system user" do
      before { new_resource.system(true) }
      it "should not pass -r" do
        expect(provider).to receive(:shell_out!).with("useradd", "adam")
        provider.create_user
      end
    end

    context "with manage_home" do
      before { new_resource.manage_home(true) }
      it "should not pass -r" do
        expect(provider).to receive(:shell_out!).with("useradd", "-m", "adam")
        provider.create_user
      end
    end
  end

  describe "when managing user locked status" do
    let(:user_lock) { "adam:FOO:::::::" }
    let(:shadow_file_contents) do
      %W{
        user1:LK:::::::
        #{user_lock}
        user2:NP:::::::
      }
    end

    describe "when determining if the user is locked" do
      before do
        allow(IO).to receive(:read).and_return(shadow_file_contents.join("\n"))
      end

      context "when user does not exist" do
        let(:user_lock) { "other_user:FOO:::::::" }

        it "should raise a sensible error" do
          expect { provider.check_lock }.to raise_error(Chef::Exceptions::User)
        end
      end

      # locked shadow lines
      [
        "adam:*LK*:::::::",
        "adam:*LK*foobar:::::::",
        "adam:*LK*bahamas10:::::::",
        "adam:*LK*goonawaLK:::::::",
        "adam:*LK*LKgir:::::::",
        "adam:*LK*L....:::::::",
      ].each do |shadow|
        context "for user 'adam' with entry '#{shadow}'" do
          let(:user_lock) { shadow }

          it "should return true" do
            expect(provider.check_lock).to eql(true)
          end
        end
      end

      # unlocked shadow lines
      [
        "adam:NP:::::::",
        "adam:*NP*:::::::",
        "adam:foobar:::::::",
        "adam:bahamas10:::::::",
        "adam:goonawaLK:::::::",
        "adam:LKgir:::::::",
        "adam:L...:::::::",
      ].each do |shadow|
        context "for user 'adam' with entry '#{shadow}'" do
          let(:user_lock) { shadow }

          it "should return false" do
            expect(provider.check_lock).to eql(false)
          end
        end
      end
    end

    describe "when locking the user" do
      it "should run passwd -l with the new resources username" do
        shell_return = shellcmdresult.new("", "", 0)
        expect(provider).to receive(:shell_out!).with("passwd", "-l", "adam").and_return(shell_return)
        provider.lock_user
      end
    end

    describe "when unlocking the user" do
      it "should run passwd -u with the new resources username" do
        shell_return = shellcmdresult.new("", "", 0)
        expect(provider).to receive(:shell_out!).with("passwd", "-u", "adam").and_return(shell_return)
        provider.unlock_user
      end
    end
  end
end
