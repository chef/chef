#
# Author:: Lee Jensen (<ljensen@engineyard.com>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))

describe Chef::Provider::Service::Gentoo do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    
    resource_opts     = { :null_object => true, :name => 'chef', :service_name => 'chef', :enabled => false, :running => nil, :supports => {} }
    @new_resource     = mock("Chef::Resource::Service", resource_opts)
    @current_resource = mock("Chef::Resource::Service", resource_opts)
    
    @provider = Chef::Provider::Service::Gentoo.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    File.stub!(:exists?).and_return(true)
    
    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each_line).and_yield("  gfs | default ")    
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)    
  end
  
  describe "load_current_resource" do  
    it "should raise Chef::Exceptions::Service if /sbin/rc-update does not exist" do
      File.should_receive(:exists?).with("/sbin/rc-update").and_return(false)
      lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
    end
  
    it "should set enabled true if rc-update indicates service is in default runlevel" do
      @stdout.should_receive(:each_line).
          and_yield('  gfs | default ').
          and_yield(' chef | default ').
          and_yield('monit | default ').
          and_yield('mysql | default ')
      @provider.should_receive(:popen4).with("/sbin/rc-update -s default").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @current_resource.should_receive(:enabled).with(true)
      @provider.load_current_resource
    end
  
    it "should set enabled false if rc-update indicates service is not in default runlevel" do
      @stdout.should_receive(:each_line).
          and_yield('    gfs | default ').
          and_yield('notchef | default ').
          and_yield('  monit | default ').
          and_yield('  mysql | default ')
      @provider.should_receive(:popen4).with("/sbin/rc-update -s default").and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      @provider.load_current_resource
      @current_resource.enabled.should be_false
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
