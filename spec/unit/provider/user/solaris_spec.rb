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

  let(:shellcmdresult) {
    Struct.new(:stdout, :stderr, :exitstatus)
  }

  subject(:provider) do
    p = described_class.new(@new_resource, @run_context)
    p.current_resource = @current_resource

    # Prevent the useradd-based provider tests from trying to write /etc/shadow
    allow(p).to receive(:write_shadow_file)
    p
  end

  describe "when we want to set a password" do
    before(:each) do
      @node = Chef::Node.new
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, {}, @events)

      @new_resource = Chef::Resource::User.new("adam", @run_context)
      @current_resource = Chef::Resource::User.new("adam", @run_context)

      @new_resource.password "hocus-pocus"

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
      @new_resource.password "verysecurepassword"
      provider.manage_user
      expect(::File.open(password_file.path, "r").read).to match(/adam:verysecurepassword:/)
      password_file.unlink
    end
  end

  describe "when managing user locked status" do
    before(:each) do
      @node = Chef::Node.new
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, {}, @events)

      @new_resource = Chef::Resource::User.new("dave")
      @current_resource = @new_resource.dup

      @provider = Chef::Provider::User::Solaris.new(@new_resource, @run_context)
      @provider.current_resource = @current_resource
    end
    describe "when determining if the user is locked" do

      # locked shadow lines
      [
        "dave:LK:::::::",
        "dave:*LK*:::::::",
        "dave:*LK*foobar:::::::",
        "dave:*LK*bahamas10:::::::",
        "dave:*LK*L....:::::::",
      ].each do |shadow|
        it "should return true if user is locked with #{shadow}" do
          shell_return = shellcmdresult.new(shadow + "\n", "", 0)
          expect(provider).to receive(:shell_out!).with("getent", "shadow", @new_resource.username).and_return(shell_return)
          expect(provider.check_lock).to eql(true)
        end
      end

      # unlocked shadow lines
      [
        "dave:NP:::::::",
        "dave:*NP*:::::::",
        "dave:foobar:::::::",
        "dave:bahamas10:::::::",
        "dave:L...:::::::",
      ].each do |shadow|
        it "should return false if user is unlocked with #{shadow}" do
          shell_return = shellcmdresult.new(shadow + "\n", "", 0)
          expect(provider).to receive(:shell_out!).with("getent", "shadow", @new_resource.username).and_return(shell_return)
          expect(provider.check_lock).to eql(false)
        end
      end
    end

    describe "when locking the user" do
      it "should run passwd -l with the new resources username" do
        shell_return = shellcmdresult.new("", "", 0)
        expect(provider).to receive(:shell_out!).with("passwd", "-l", @new_resource.username).and_return(shell_return)
        provider.lock_user
      end
    end

    describe "when unlocking the user" do
      it "should run passwd -u with the new resources username" do
        shell_return = shellcmdresult.new("", "", 0)
        expect(provider).to receive(:shell_out!).with("passwd", "-u", @new_resource.username).and_return(shell_return)
        provider.unlock_user
      end
    end
  end
end
