#
# Author:: Cary Penniman (<cary@rightscale.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

describe Chef::Resource::Log do

  before(:each) do
    @log_str = "this is my string to log"
    @resource = Chef::Resource::Log.new(@log_str)
  end  
 
  it "should create a new Chef::Resource::Log" do
      @resource.should be_a_kind_of(Chef::Resource)
      @resource.should be_a_kind_of(Chef::Resource::Log)
    end

  it "should have a name of log" do
    @resource.resource_name.should == :log
  end

  it "should allow you to set a log string" do
    @resource.name.should == @log_str
  end

  it "should set the message to the first argument to new" do
    @resource.message.should == @log_str
  end

  it "should accept a string for the log message" do
    @resource.message "this is different"
    @resource.message.should == "this is different"
  end
  
  it "should accept a vaild level option" do
    @resource.level :debug
    @resource.level :info
    @resource.level :warn
    @resource.level :error
    @resource.level :fatal
    lambda { @resource.level :unsupported }.should raise_error(ArgumentError)
  end

  describe "when the identity is defined" do
    before do 
      @resource = Chef::Resource::Log.new("ery day I'm loggin-in")
    end

    it "returns the log string as its identity" do
      @resource.identity.should == "ery day I'm loggin-in"
    end
  end
end
  
