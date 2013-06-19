#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
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

require 'spec_helper'
require 'ostruct'

describe Chef::Daemon do
  before do
    @original_config = Chef::Config.configuration
    if windows?
      mock_struct = #Struct::Passwd.new(nil, nil, 111, 111)
      mock_struct = OpenStruct.new(:uid => 2342, :gid => 2342)
      Etc.stub!(:getpwnam).and_return mock_struct
      Etc.stub!(:getgrnam).and_return mock_struct
      # mock unimplemented methods
      Process.stub!(:initgroups).and_return nil
      Process::GID.stub!(:change_privilege).and_return 11
      Process::UID.stub!(:change_privilege).and_return 11
    end
  end

  after do
    Chef::Config.configuration.replace(@original_config)
  end

  describe ".running?" do

    before do
      Chef::Daemon.name = "spec"
    end

    describe "when a pid file exists" do

      before do
        Chef::Daemon.stub!(:pid_from_file).and_return(1337)
      end

      it "should check that there is a process matching the pidfile" do
        Process.should_receive(:kill).with(0, 1337)
        Chef::Daemon.running?
      end

    end

    describe "when the pid file is nonexistent" do

      before do
        Chef::Daemon.stub!(:pid_from_file).and_return(nil)
      end

      it "should return false" do
        Chef::Daemon.running?.should be_false
      end

    end
  end

  describe ".pid_file" do

    describe "when the pid_file option has been set" do

      before do
        Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
      end

      after do
        Chef::Config.configuration.replace(@original_config)
      end

      it "should return the supplied value" do
        Chef::Daemon.pid_file.should eql("/var/run/chef/chef-client.pid")
      end
    end

    describe "without the pid_file option set" do

      before do
        Chef::Config[:pid_file] = nil
        Chef::Daemon.name = "chef-client"
      end

      it "should return a valued based on @name" do
        Chef::Daemon.pid_file.should eql("/tmp/chef-client.pid")
      end

    end
  end

  describe ".pid_from_file" do

    before do
      Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
    end

    it "should suck the pid out of pid_file" do
      File.should_receive(:read).with("/var/run/chef/chef-client.pid").and_return("1337")
      Chef::Daemon.pid_from_file
    end
  end

  describe ".save_pid_file" do

    before do
      Process.stub!(:pid).and_return(1337)
      Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
      Chef::Application.stub!(:fatal!).and_return(true)
      @f_mock = mock(File, { :print => true, :close => true, :write => true })
      File.stub!(:open).with("/var/run/chef/chef-client.pid", "w").and_yield(@f_mock)
    end

    it "should try and create the parent directory" do
      FileUtils.should_receive(:mkdir_p).with("/var/run/chef")
      Chef::Daemon.save_pid_file
    end

    it "should open the pid file for writing" do
      File.should_receive(:open).with("/var/run/chef/chef-client.pid", "w")
      Chef::Daemon.save_pid_file
    end

    it "should write the pid, converted to string, to the pid file" do
      @f_mock.should_receive(:write).with("1337").once.and_return(true)
      Chef::Daemon.save_pid_file
    end

  end

  describe ".remove_pid_file" do
    before do
      Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
    end

    describe "when the pid file exists" do

      before do
        File.stub!(:exists?).with("/var/run/chef/chef-client.pid").and_return(true)
      end

      it "should remove the file" do
        FileUtils.should_receive(:rm).with("/var/run/chef/chef-client.pid")
        Chef::Daemon.remove_pid_file
      end


    end

    describe "when the pid file exists and the process is forked" do

      before do
        File.stub!(:exists?).with("/var/run/chef/chef-client.pid").and_return(true)
        Chef::Daemon.stub!(:forked?) { true }
      end

      it "should not remove the file" do
        FileUtils.should_not_receive(:rm)
        Chef::Daemon.remove_pid_file
      end

    end

    describe "when the pid file exists and the process is not forked" do
      before do
        File.stub!(:exists?).with("/var/run/chef/chef-client.pid").and_return(true)
        Chef::Daemon.stub!(:forked?) { false }
      end

      it "should remove the file" do
        FileUtils.should_receive(:rm)
        Chef::Daemon.remove_pid_file
      end
    end

    describe "when the pid file does not exist" do

      before do
        File.stub!(:exists?).with("/var/run/chef/chef-client.pid").and_return(false)
      end

      it "should not remove the file" do
        FileUtils.should_not_receive(:rm)
        Chef::Daemon.remove_pid_file
      end

    end
  end

  describe ".change_privilege" do

    before do
      Chef::Application.stub!(:fatal!).and_return(true)
      Chef::Config[:user] = 'aj'
      Dir.stub!(:chdir)
    end

    it "changes the working directory to root" do
      Dir.rspec_reset
      Dir.should_receive(:chdir).with("/").and_return(0)
      Chef::Daemon.change_privilege
    end

    describe "when the user and group options are supplied" do

      before do
        Chef::Config[:group] = 'staff'
      end

      it "should log an appropriate info message" do
        Chef::Log.should_receive(:info).with("About to change privilege to aj:staff")
        Chef::Daemon.change_privilege
      end

      it "should call _change_privilege with the user and group" do
        Chef::Daemon.should_receive(:_change_privilege).with("aj", "staff")
        Chef::Daemon.change_privilege
      end
    end

    describe "when just the user option is supplied" do
      before do
        Chef::Config[:group] = nil
      end

      it "should log an appropriate info message" do
        Chef::Log.should_receive(:info).with("About to change privilege to aj")
        Chef::Daemon.change_privilege
      end

      it "should call _change_privilege with just the user" do
        Chef::Daemon.should_receive(:_change_privilege).with("aj")
        Chef::Daemon.change_privilege
      end
    end
  end

  describe "._change_privilege" do

    before do
      Process.stub!(:euid).and_return(0)
      Process.stub!(:egid).and_return(0)

      Process::UID.stub!(:change_privilege).and_return(nil)
      Process::GID.stub!(:change_privilege).and_return(nil)

      @pw_user = mock("Struct::Passwd", :uid => 501)
      @pw_group = mock("Struct::Group", :gid => 20)

      Process.stub!(:initgroups).and_return(true)

      Etc.stub!(:getpwnam).and_return(@pw_user)
      Etc.stub!(:getgrnam).and_return(@pw_group)
    end

    describe "with sufficient privileges" do
      before do
        Process.stub!(:euid).and_return(0)
        Process.stub!(:egid).and_return(0)
      end

      it "should initialize the supplemental group list" do
        Process.should_receive(:initgroups).with("aj", 20)
        Chef::Daemon._change_privilege("aj")
      end

      it "should attempt to change the process GID" do
        Process::GID.should_receive(:change_privilege).with(20).and_return(20)
        Chef::Daemon._change_privilege("aj")
      end

      it "should attempt to change the process UID" do
        Process::UID.should_receive(:change_privilege).with(501).and_return(501)
        Chef::Daemon._change_privilege("aj")
      end
    end

    describe "with insufficient privileges" do
      before do
        Process.stub!(:euid).and_return(999)
        Process.stub!(:egid).and_return(999)
      end

      it "should log an appropriate error message and fail miserably" do
        Process.stub!(:initgroups).and_raise(Errno::EPERM)
        error = "Operation not permitted"
        if RUBY_PLATFORM.match("solaris2") || RUBY_PLATFORM.match("aix")
          error = "Not owner"
        end
        Chef::Application.should_receive(:fatal!).with("Permission denied when trying to change 999:999 to 501:20. #{error}")
        Chef::Daemon._change_privilege("aj")
      end
    end

  end
end
