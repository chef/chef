#
# Author:: Lee Jensen (<ljensen@engineyard.com>)
# Author:: AJ Christensen (<aj@opscode.com>)
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

describe Chef::Provider::Service::Gentoo do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    
    @new_resource     = Chef::Resource::Service.new("chef")
    @current_resource = Chef::Resource::Service.new("chef")
    
    @provider = Chef::Provider::Service::Gentoo.new(@new_resource, @run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    @status = mock("Status", :exitstatus => 0, :stdout => @stdout)
    @provider.stub!(:shell_out).and_return(@status)
    File.stub!(:exists?).with("/etc/init.d/chef").and_return(true)
    File.stub!(:exists?).with("/sbin/rc-update").and_return(true)
    File.stub!(:exists?).with("/etc/runlevels/default/chef").and_return(false)
    File.stub!(:readable?).with("/etc/runlevels/default/chef").and_return(false)
  end
 # new test: found_enabled state
  #
  describe "load_current_resource" do  
    it "should raise Chef::Exceptions::Service if /sbin/rc-update does not exist" do
      File.should_receive(:exists?).with("/sbin/rc-update").and_return(false)
      @provider.define_resource_requirements
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
    end

    it "should track when service file is not found in /etc/runlevels" do
      @provider.load_current_resource
      @provider.instance_variable_get("@found_script").should be_false
    end

    it "should track when service file is found in /etc/runlevels/**/" do
      Dir.stub!(:glob).with("/etc/runlevels/**/chef").and_return(["/etc/runlevels/default/chef"])
      @provider.load_current_resource
      @provider.instance_variable_get("@found_script").should be_true
    end

    describe "when detecting the service enable state" do
      describe "and the glob returns a default service script file" do
        before do
          Dir.stub!(:glob).with("/etc/runlevels/**/chef").and_return(["/etc/runlevels/default/chef"])
        end

        describe "and the file exists and is readable" do
          before do
            File.stub!(:exists?).with("/etc/runlevels/default/chef").and_return(true)
            File.stub!(:readable?).with("/etc/runlevels/default/chef").and_return(true)
          end
          it "should set enabled to true" do
            @provider.load_current_resource
            @current_resource.enabled.should be_true
          end
        end

        describe "and the file exists but is not readable" do
          before do
            File.stub!(:exists?).with("/etc/runlevels/default/chef").and_return(true)
            File.stub!(:readable?).with("/etc/runlevels/default/chef").and_return(false)
          end
          
          it "should set enabled to false" do
            @provider.load_current_resource
            @current_resource.enabled.should be_false
          end
        end

        describe "and the file does not exist" do
          before do
            File.stub!(:exists?).with("/etc/runlevels/default/chef").and_return(false)
            File.stub!(:readable?).with("/etc/runlevels/default/chef").and_return("foobarbaz")
          end

          it "should set enabled to false" do
            @provider.load_current_resource
            @current_resource.enabled.should be_false
          end

        end
      end

  end
 
    it "should return the current_resource" do
      @provider.load_current_resource.should == @current_resource
    end  

    it "should support the status command automatically" do
      @provider.load_current_resource
      @new_resource.supports[:status].should be_true
    end

    it "should support the restart command automatically" do
      @provider.load_current_resource
      @new_resource.supports[:restart].should be_true
    end

    it "should not support the reload command automatically" do
      @provider.load_current_resource
      @new_resource.supports[:reload].should_not be_true
    end

  end
  
  describe "action_methods" do
    before(:each) { @provider.stub!(:load_current_resource).and_return(@current_resource) }

    describe Chef::Provider::Service::Gentoo, "enable_service" do
      it "should call rc-update add *service* default" do
        @provider.should_receive(:run_command).with({:command => "/sbin/rc-update add chef default"})
        @provider.enable_service()
      end
    end

    describe Chef::Provider::Service::Gentoo, "disable_service" do
      it "should call rc-update del *service* default" do
        @provider.should_receive(:run_command).with({:command => "/sbin/rc-update del chef default"})
        @provider.disable_service()
      end
    end
  end

end
