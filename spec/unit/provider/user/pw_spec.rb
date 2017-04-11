#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::Provider::User::Pw do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::User::PwUser.new("adam")
    @new_resource.comment   "Adam Jacob"
    @new_resource.uid       1000
    @new_resource.gid       1000
    @new_resource.home      "/home/adam"
    @new_resource.shell     "/usr/bin/zsh"
    @new_resource.password  "abracadabra"

    @new_resource.manage_home true

    @current_resource = Chef::Resource::User::PwUser.new("adam")
    @current_resource.comment  "Adam Jacob"
    @current_resource.uid      1000
    @current_resource.gid      1000
    @current_resource.home     "/home/adam"
    @current_resource.shell    "/usr/bin/zsh"
    @current_resource.password "abracadabra"

    @provider = Chef::Provider::User::Pw.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
  end

  describe "setting options to the pw command" do
    field_list = {
      "comment" => "-c",
      "home" => "-d",
      "gid" => "-g",
      "uid" => "-u",
      "shell" => "-s",
    }
    field_list.each do |attribute, option|
      it "should check for differences in #{attribute} between the new and current resources" do
        expect(@current_resource).to receive(attribute)
        expect(@new_resource).to receive(attribute)
        @provider.set_options
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
        allow(@new_resource).to receive(attribute).and_return("hola")
        expect(@provider.set_options).to eql([ @new_resource.username, option, @new_resource.send(attribute), "-m"])
      end
    end

    it "should combine all the possible options" do
      match_array = [ "adam" ]
      field_list.sort { |a, b| a[0] <=> b[0] }.each do |attribute, option|
        allow(@new_resource).to receive(attribute).and_return("hola")
        match_array << option
        match_array << "hola"
      end
      match_array << "-m"
      expect(@provider.set_options).to eql(match_array)
    end
  end

  describe "create_user" do
    before(:each) do
      allow(@provider).to receive(:shell_out!).and_return(true)
      allow(@provider).to receive(:modify_password).and_return(true)
    end

    it "should run pw useradd with the return of set_options" do
      expect(@provider).to receive(:shell_out!).with("pw", "useradd", "adam", "-m").and_return(true)
      @provider.create_user
    end

    it "should modify the password" do
      expect(@provider).to receive(:modify_password).and_return(true)
      @provider.create_user
    end
  end

  describe "manage_user" do
    before(:each) do
      allow(@provider).to receive(:shell_out!).and_return(true)
      allow(@provider).to receive(:modify_password).and_return(true)
    end

    it "should run pw usermod with the return of set_options" do
      expect(@provider).to receive(:shell_out!).with("pw", "usermod", "adam", "-m").and_return(true)
      @provider.manage_user
    end

    it "should modify the password" do
      expect(@provider).to receive(:modify_password).and_return(true)
      @provider.create_user
    end
  end

  describe "remove_user" do
    it "should run pw userdel with the new resources user name" do
      @new_resource.manage_home false
      expect(@provider).to receive(:shell_out!).with("pw", "userdel", @new_resource.username).and_return(true)
      @provider.remove_user
    end

    it "should run pw userdel with the new resources user name and -r if manage_home is true" do
      expect(@provider).to receive(:shell_out!).with("pw", "userdel", @new_resource.username, "-r").and_return(true)
      @provider.remove_user
    end
  end

  describe "determining if the user is locked" do
    it "should return true if user is locked" do
      allow(@current_resource).to receive(:password).and_return("*LOCKED*abracadabra")
      expect(@provider.check_lock).to eql(true)
    end

    it "should return false if user is not locked" do
      allow(@current_resource).to receive(:password).and_return("abracadabra")
      expect(@provider.check_lock).to eql(false)
    end
  end

  describe "when locking the user" do
    it "should run pw lock with the new resources username" do
      expect(@provider).to receive(:shell_out!).with("pw", "lock", @new_resource.username)
      @provider.lock_user
    end
  end

  describe "when unlocking the user" do
    it "should run pw unlock with the new resources username" do
      expect(@provider).to receive(:shell_out!).with("pw", "unlock", @new_resource.username)
      @provider.unlock_user
    end
  end

  describe "when modifying the password" do
    before(:each) do
      @status = double("Status", exitstatus: 0)
      allow(@provider).to receive(:shell_out!).and_return(@status)
    end

    describe "and the new password has not been specified" do
      before(:each) do
        @new_resource.password(nil)
      end

      it "logs an appropriate message" do
        @provider.modify_password
      end
    end

    describe "and the new password has been specified" do
      before(:each) do
        @new_resource.password("abracadabra")
      end

      it "should check for differences in password between the new and current resources" do
        expect(@current_resource).to receive(:password)
        expect(@new_resource).to receive(:password).and_call_original.at_least(:once)
        @provider.modify_password
      end
    end

    describe "and the passwords are identical" do
      before(:each) do
        @new_resource.password("abracadabra")
        allow(@current_resource).to receive(:password).and_return("abracadabra")
      end

      it "logs an appropriate message" do
        @provider.modify_password
      end
    end

    describe "and the passwords are different" do
      before(:each) do
        @new_resource.password("abracadabra")
        allow(@current_resource).to receive(:password).and_return("sesame")
      end

      it "should log an appropriate message" do
        @provider.modify_password
      end

      it "should run pw usermod with the username and the option -H 0" do
        expect(@provider).to receive(:shell_out!).with("pw usermod adam -H 0", { :input => "abracadabra" }).and_return(@status)
        @provider.modify_password
      end

      it "should raise an exception if pw usermod fails" do
        expect(@provider).to receive(:shell_out!).and_raise(Mixlib::ShellOut::ShellCommandFailed)
        expect { @provider.modify_password }.to raise_error(Mixlib::ShellOut::ShellCommandFailed)
      end

      it "should not raise an exception if pw usermod succeeds" do
        expect { @provider.modify_password }.not_to raise_error
      end
    end
  end

  describe "when loading the current state" do
    before do
      @provider.new_resource = Chef::Resource::User::PwUser.new("adam")
    end

    it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/pw").and_return(false)
      expect { @provider.load_current_resource }.to raise_error(Chef::Exceptions::User)
    end

    it "shouldn't raise an error if /usr/sbin/pw exists" do
      allow(File).to receive(:exist?).and_return(true)
      expect { @provider.load_current_resource }.not_to raise_error
    end
  end
end
