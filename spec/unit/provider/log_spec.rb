#
# Author:: Cary Penniman (<cary@rightscale.com>)
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

describe Chef::Provider::Log::ChefLog do

  before(:each) do
    @log_str = "this is my test string to log"
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
  end  

  it "should be registered with the default platform hash" do
    Chef::Platform.platforms[:default][:log].should_not be_nil
  end

  it "should write the string to the Chef::Log object at default level (info)" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:info).with(@log_str).and_return(true)
      @provider.action_write
  end
  
  it "should write the string to the Chef::Log object at debug level" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @new_resource.level :debug
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:debug).with(@log_str).and_return(true)
      @provider.action_write
  end

  it "should write the string to the Chef::Log object at info level" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @new_resource.level :info
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:info).with(@log_str).and_return(true)
      @provider.action_write
  end
  
  it "should write the string to the Chef::Log object at warn level" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @new_resource.level :warn
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:warn).with(@log_str).and_return(true)
      @provider.action_write
  end
  
  it "should write the string to the Chef::Log object at error level" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @new_resource.level :error
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:error).with(@log_str).and_return(true)
      @provider.action_write
  end
  
  it "should write the string to the Chef::Log object at fatal level" do
      @new_resource = Chef::Resource::Log.new(@log_str)
      @new_resource.level :fatal
      @provider = Chef::Provider::Log::ChefLog.new(@new_resource, @run_context)
      Chef::Log.should_receive(:fatal).with(@log_str).and_return(true)
      @provider.action_write
  end
  
end
