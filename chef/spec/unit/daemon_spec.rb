#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Daemon do  
=begin
  # I don't think I can test daemonize, cause, well, it exits! SystemExit
  # Feel free to re-enable this
  describe "daemonize" do
    it "should set @name" do
     Chef::Daemon.should_receive(:name).with("chef-client")  
     Chef::Daemon.daemonize("chef-client")
    end
    
    it "should check for a pid file based on name" do
      Chef::Daemon.should_receive(:running?)
      Chef::Daemon.daemonize("chef-client")
    end
  end
=end
  
  describe "running?" do
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
 
  describe "pid_file" do
    
    describe "when the pid_file option has been set" do
      before do
        Chef::Config.stub!(:[]).with(:pid_file).and_return("/var/run/chef/chef-client.pid")
      end
      
      it "should return the supplied value" do
        Chef::Daemon.pid_file.should eql("/var/run/chef/chef-client.pid")
      end
    end
    
    describe "without the pid_file option set" do
      before do
        Chef::Config.stub!(:[]).with(:pid_file).and_return(nil)
        Chef::Daemon.name = "chef-client"
      end
      
      it "should return a valued based on @name" do
        Chef::Daemon.pid_file.should eql("/tmp/chef-client.pid")
      end
    end
  end
  
  describe "pid_from_file" do
    before do
      Chef::Config.stub!(:[]).with(:pid_file).and_return("/var/run/chef/chef-client.pid")
    end
    it "should suck the pid out of pid_file" do
      File.should_receive(:read).with("/var/run/chef/chef-client.pid").and_return("1337")
      Chef::Daemon.pid_from_file
    end
  end
  
  describe "save_pid_file" do
    
  end
  
  describe "remove_pid_file" do
    
  end
  
  describe "change_privilege" do
    
  end
  
  describe "_change_privilege" do
    
  end
end