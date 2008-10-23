#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Service do

  before(:each) do
    @resource = Chef::Resource::Service.new("chef")
  end  

  it "should create a new Chef::Resource::Service" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Service)
  end

  it "should set the service_name to the first argument to new" do
    @resource.service_name.should eql("chef")
  end

  it "should set the pattern to be the service name by default" do
    @resource.pattern.should eql("chef")
  end

  it "should accept a string for the service name" do
    @resource.service_name "something"
    @resource.service_name.should eql("something")
  end
 
  it "should accept a string for the service pattern" do
    @resource.pattern ".*"
    @resource.pattern.should eql(".*")
  end

  it "should not accept a regexp for the service pattern" do
    lambda {
      @resource.pattern /.*/
    }.should raise_error(ArgumentError)
  end
  
  it "should accept a string for the service start command" do
    @resource.start_command "/etc/init.d/chef start"
    @resource.start_command.should eql("/etc/init.d/chef start")
  end

  it "should not accept a regexp for the service start command" do
    lambda {
      @resource.start_command /.*/
    }.should raise_error(ArgumentError)
  end
  
  it "should accept a string for the service stop command" do
    @resource.stop_command "/etc/init.d/chef stop"
    @resource.stop_command.should eql("/etc/init.d/chef stop")
  end

  it "should not accept a regexp for the service stop command" do
    lambda {
      @resource.stop_command /.*/
    }.should raise_error(ArgumentError)
  end
  
  it "should accept a string for the service status command" do
    @resource.status_command "/etc/init.d/chef status"
    @resource.status_command.should eql("/etc/init.d/chef status")
  end
  
  it "should not accept a regexp for the service status command" do
    lambda {
      @resource.status_command /.*/
    }.should raise_error(ArgumentError)
  end
  
  it "should accept a string for the service restart command" do
    @resource.restart_command "/etc/init.d/chef restart"
    @resource.restart_command.should eql("/etc/init.d/chef restart")
  end
  
  it "should not accept a regexp for the service restart command" do
    lambda {
      @resource.restart_command /.*/
    }.should raise_error(ArgumentError)
  end
  
  %w{enabled running}.each do |attrib|
    it "should accept true for #{attrib}" do
      @resource.send(attrib, true) 
      @resource.send(attrib).should eql(true)
    end
  
    it "should accept false for #{attrib}" do
      @resource.send(attrib, false)
      @resource.send(attrib).should eql(false)
    end
  
    it "should not accept a string for #{attrib}" do
      lambda { @resource.send(attrib, "poop") }.should raise_error(ArgumentError)
    end
  end
end
