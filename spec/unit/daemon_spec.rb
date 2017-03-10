#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "spec_helper"
require "ostruct"

describe Chef::Daemon do
  before do
    if windows?
      mock_struct = #Struct::Passwd.new(nil, nil, 111, 111)
        mock_struct = OpenStruct.new(:uid => 2342, :gid => 2342)
      allow(Etc).to receive(:getpwnam).and_return mock_struct
      allow(Etc).to receive(:getgrnam).and_return mock_struct
      # mock unimplemented methods
      allow(Process).to receive(:initgroups).and_return nil
      allow(Process::GID).to receive(:change_privilege).and_return 11
      allow(Process::UID).to receive(:change_privilege).and_return 11
    end
  end

  describe ".pid_file" do

    describe "when the pid_file option has been set" do

      before do
        Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
      end

      it "should return the supplied value" do
        expect(Chef::Daemon.pid_file).to eql("/var/run/chef/chef-client.pid")
      end
    end

    describe "without the pid_file option set" do

      before do
        Chef::Daemon.name = "chef-client"
      end

      it "should return a valued based on @name" do
        expect(Chef::Daemon.pid_file).to eql("/tmp/chef-client.pid")
      end

    end
  end

  describe ".pid_from_file" do

    before do
      Chef::Config[:pid_file] = "/var/run/chef/chef-client.pid"
    end

    it "should suck the pid out of pid_file" do
      expect(File).to receive(:read).with("/var/run/chef/chef-client.pid").and_return("1337")
      Chef::Daemon.pid_from_file
    end
  end

  describe ".change_privilege" do

    before do
      allow(Chef::Application).to receive(:fatal!).and_return(true)
      Chef::Config[:user] = "aj"
      allow(Dir).to receive(:chdir)
    end

    it "changes the working directory to root" do
      expect(Dir).to receive(:chdir).with("/").and_return(0)
      Chef::Daemon.change_privilege
    end

    describe "when the user and group options are supplied" do

      before do
        Chef::Config[:group] = "staff"
      end

      it "should log an appropriate info message" do
        expect(Chef::Log).to receive(:info).with("About to change privilege to aj:staff")
        Chef::Daemon.change_privilege
      end

      it "should call _change_privilege with the user and group" do
        expect(Chef::Daemon).to receive(:_change_privilege).with("aj", "staff")
        Chef::Daemon.change_privilege
      end
    end

    describe "when just the user option is supplied" do
      it "should log an appropriate info message" do
        expect(Chef::Log).to receive(:info).with("About to change privilege to aj")
        Chef::Daemon.change_privilege
      end

      it "should call _change_privilege with just the user" do
        expect(Chef::Daemon).to receive(:_change_privilege).with("aj")
        Chef::Daemon.change_privilege
      end
    end
  end

  describe "._change_privilege" do

    before do
      allow(Process).to receive(:euid).and_return(0)
      allow(Process).to receive(:egid).and_return(0)

      allow(Process::UID).to receive(:change_privilege).and_return(nil)
      allow(Process::GID).to receive(:change_privilege).and_return(nil)

      @pw_user = double("Struct::Passwd", :uid => 501)
      @pw_group = double("Struct::Group", :gid => 20)

      allow(Process).to receive(:initgroups).and_return(true)

      allow(Etc).to receive(:getpwnam).and_return(@pw_user)
      allow(Etc).to receive(:getgrnam).and_return(@pw_group)
    end

    describe "with sufficient privileges" do
      before do
        allow(Process).to receive(:euid).and_return(0)
        allow(Process).to receive(:egid).and_return(0)
      end

      it "should initialize the supplemental group list" do
        expect(Process).to receive(:initgroups).with("aj", 20)
        Chef::Daemon._change_privilege("aj")
      end

      it "should attempt to change the process GID" do
        expect(Process::GID).to receive(:change_privilege).with(20).and_return(20)
        Chef::Daemon._change_privilege("aj")
      end

      it "should attempt to change the process UID" do
        expect(Process::UID).to receive(:change_privilege).with(501).and_return(501)
        Chef::Daemon._change_privilege("aj")
      end
    end

    describe "with insufficient privileges" do
      before do
        allow(Process).to receive(:euid).and_return(999)
        allow(Process).to receive(:egid).and_return(999)
      end

      it "should log an appropriate error message and fail miserably" do
        allow(Process).to receive(:initgroups).and_raise(Errno::EPERM)
        error = "Operation not permitted"
        if RUBY_PLATFORM.match("solaris2") || RUBY_PLATFORM.match("aix")
          error = "Not owner"
        end
        expect(Chef::Application).to receive(:fatal!).with("Permission denied when trying to change 999:999 to 501:20. #{error}")
        Chef::Daemon._change_privilege("aj")
      end
    end

  end
end
