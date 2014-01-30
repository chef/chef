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
    if windows?
      mock_struct = #Struct::Passwd.new(nil, nil, 111, 111)
      mock_struct = OpenStruct.new(:uid => 2342, :gid => 2342)
      Etc.stub(:getpwnam).and_return mock_struct
      Etc.stub(:getgrnam).and_return mock_struct
      # mock unimplemented methods
      Process.stub(:initgroups).and_return nil
      Process::GID.stub(:change_privilege).and_return 11
      Process::UID.stub(:change_privilege).and_return 11
    end
  end

  describe ".pid_file" do

    describe "when the pid_file option has been set" do

      before do
        Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
      end

      it "should return the supplied value" do
        Chef::Daemon.pid_file.should eql("/var/run/chef/chef-client.pid")
      end
    end

    describe "without the pid_file option set" do

      before do
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

  describe ".change_privilege" do

    before do
      Chef::Application.stub(:fatal!).and_return(true)
      Chef::Config[:user] = 'aj'
      Dir.stub(:chdir)
    end

    it "changes the working directory to root" do
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
      Process.stub(:euid).and_return(0)
      Process.stub(:egid).and_return(0)

      Process::UID.stub(:change_privilege).and_return(nil)
      Process::GID.stub(:change_privilege).and_return(nil)

      @pw_user = double("Struct::Passwd", :uid => 501)
      @pw_group = double("Struct::Group", :gid => 20)

      Process.stub(:initgroups).and_return(true)

      Etc.stub(:getpwnam).and_return(@pw_user)
      Etc.stub(:getgrnam).and_return(@pw_group)
    end

    describe "with sufficient privileges" do
      before do
        Process.stub(:euid).and_return(0)
        Process.stub(:egid).and_return(0)
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
        Process.stub(:euid).and_return(999)
        Process.stub(:egid).and_return(999)
      end

      it "should log an appropriate error message and fail miserably" do
        Process.stub(:initgroups).and_raise(Errno::EPERM)
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
