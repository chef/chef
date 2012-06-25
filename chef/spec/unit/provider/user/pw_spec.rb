#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Provider::User::Pw do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource = Chef::Resource::User.new("adam")
    @new_resource.comment   "Adam Jacob"
    @new_resource.uid       1000
    @new_resource.gid       1000
    @new_resource.home      "/home/adam"
    @new_resource.shell     "/usr/bin/zsh"
    @new_resource.password  "abracadabra"
    
    @new_resource.supports :manage_home => true

    @current_resource = Chef::Resource::User.new("adam")
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
      'comment' => "-c",
      'home' => "-d",
      'gid' => "-g",
      'uid' => "-u",
      'shell' => "-s"
    }
    field_list.each do |attribute, option|
      it "should check for differences in #{attribute} between the new and current resources" do
        @current_resource.should_receive(attribute)
        @new_resource.should_receive(attribute)
        @provider.set_options
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not null" do
        @new_resource.stub!(attribute).and_return("hola")
        @provider.set_options.should eql(" #{@new_resource.username} #{option} '#{@new_resource.send(attribute)}' -m")
      end

      it "should set the option for #{attribute} if the new resources #{attribute} is not null, without homedir management" do
        @new_resource.stub!(:supports).and_return({:manage_home => false})
        @new_resource.stub!(attribute).and_return("hola")
        @provider.set_options.should eql(" #{@new_resource.username} #{option} '#{@new_resource.send(attribute)}'")
      end
    end

    it "should combine all the possible options" do
      match_string = " adam"
      field_list.sort{ |a,b| a[0] <=> b[0] }.each do |attribute, option|
        @new_resource.stub!(attribute).and_return("hola")
        match_string << " #{option} 'hola'"
      end
      match_string << " -m"
      @provider.set_options.should eql(match_string)
    end
  end

  describe "create_user" do
    before(:each) do
      @provider.stub!(:run_command).and_return(true)
      @provider.stub!(:modify_password).and_return(true)
    end

    it "should run pw useradd with the return of set_options" do
      @provider.should_receive(:run_command).with({ :command => "pw useradd adam -m" }).and_return(true)
      @provider.create_user
    end

    it "should modify the password" do
      @provider.should_receive(:modify_password).and_return(true)
      @provider.create_user
    end
  end

  describe "manage_user" do
    before(:each) do
      @provider.stub!(:run_command).and_return(true)
      @provider.stub!(:modify_password).and_return(true)
    end

    it "should run pw usermod with the return of set_options" do
      @provider.should_receive(:run_command).with({ :command => "pw usermod adam -m" }).and_return(true)
      @provider.manage_user
    end

    it "should modify the password" do
      @provider.should_receive(:modify_password).and_return(true)
      @provider.create_user
    end
  end

  describe "remove_user" do
    it "should run pw userdel with the new resources user name" do
      @new_resource.supports :manage_home => false
      @provider.should_receive(:run_command).with({ :command => "pw userdel #{@new_resource.username}" }).and_return(true)
      @provider.remove_user
    end

    it "should run pw userdel with the new resources user name and -r if manage_home is true" do
      @provider.should_receive(:run_command).with({ :command => "pw userdel #{@new_resource.username} -r"}).and_return(true)
      @provider.remove_user
    end
  end

  describe "determining if the user is locked" do
    it "should return true if user is locked" do
      @current_resource.stub!(:password).and_return("*LOCKED*abracadabra")
      @provider.check_lock.should eql(true)
    end

    it "should return false if user is not locked" do
      @current_resource.stub!(:password).and_return("abracadabra")
      @provider.check_lock.should eql(false)
    end
  end

  describe "when locking the user" do
    it "should run pw lock with the new resources username" do
      @provider.should_receive(:run_command).with({ :command => "pw lock #{@new_resource.username}"})
      @provider.lock_user
    end
  end

  describe "when unlocking the user" do
    it "should run pw unlock with the new resources username" do
      @provider.should_receive(:run_command).with({ :command => "pw unlock #{@new_resource.username}"})
      @provider.unlock_user
    end
  end

  describe "when modifying the password" do
    before(:each) do
      @status = mock("Status", :exitstatus => 0)
      @provider.stub!(:popen4).and_return(@status)
      @pid, @stdin, @stdout, @stderr = nil, nil, nil, nil
    end

    it "should check for differences in password between the new and current resources" do
      @current_resource.should_receive(:password)
      @new_resource.should_receive(:password)
      @provider.modify_password
    end

    describe "and the passwords are identical" do
      before(:each) do
        @new_resource.stub!(:password).and_return("abracadabra")
        @current_resource.stub!(:password).and_return("abracadabra")
      end

      it "logs an appropriate message" do
        Chef::Log.should_receive(:debug).with("user[adam] no change needed to password")
        @provider.modify_password
      end
    end

    describe "and the passwords are different" do
      before(:each) do
        @new_resource.stub!(:password).and_return("abracadabra")
        @current_resource.stub!(:password).and_return("sesame")
      end

      it "should log an appropriate message" do
        Chef::Log.should_receive(:debug).with("user[adam] updating password")
        @provider.modify_password
      end

      it "should run pw usermod with the username and the option -H 0" do
        @provider.should_receive(:popen4).with("pw usermod adam -H 0", :waitlast => true).and_return(@status)
        @provider.modify_password
      end

      it "should send the new password to the stdin of pw usermod" do
        @stdin = StringIO.new
        @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
        @provider.modify_password
        @stdin.string.should == "abracadabra\n"
      end

      it "should raise an exception if pw usermod fails" do
        @status.should_receive(:exitstatus).and_return(1)
        lambda { @provider.modify_password }.should raise_error(Chef::Exceptions::User)
      end

      it "should not raise an exception if pw usermod succeeds" do
        @status.should_receive(:exitstatus).and_return(0)
        lambda { @provider.modify_password }.should_not raise_error(Chef::Exceptions::User)
      end
    end
  end

  describe "when loading the current state" do
    before do
      @provider.new_resource = Chef::Resource::User.new("adam")
    end

    it "should raise an error if the required binary /usr/sbin/pw doesn't exist" do
      File.should_receive(:exists?).with("/usr/sbin/pw").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::User)
    end

    it "shouldn't raise an error if /usr/sbin/pw exists" do
      File.stub!(:exists?).and_return(true)
      lambda { @provider.load_current_resource }.should_not raise_error(Chef::Exceptions::User)
    end
  end
end
