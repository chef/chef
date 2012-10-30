#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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
require 'ostruct'

shared_examples_for "define_resource_requirements_common" do
  it "should raise an error if /sbin/chkconfig does not exist" do
    File.stub!(:exists?).with("/sbin/chkconfig").and_return(false)
    @provider.stub!(:shell_out).with("/sbin/service chef status").and_raise(Errno::ENOENT)
    @provider.stub!(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_raise(Errno::ENOENT)
    @provider.load_current_resource
    @provider.define_resource_requirements
    lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
  end

  it "should not raise an error if the service exists but is not added to any runlevels" do
    status = mock("Status", :exitstatus => 0, :stdout => "" , :stderr => "")
    @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
    chkconfig = mock("Chkconfig", :exitstatus => 0, :stdout => "", :stderr => "service chef supports chkconfig, but is not referenced in any runlevel (run 'chkconfig --add chef')")
    @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
    @provider.load_current_resource
    @provider.define_resource_requirements
    lambda { @provider.process_resource_requirements }.should_not raise_error
  end
end

describe "Chef::Provider::Service::Redhat" do

  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = {:ps => 'foo'}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
 
    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Redhat.new(@new_resource, @run_context)
    @provider.action = :start
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    File.stub!(:exists?).with("/sbin/chkconfig").and_return(true)
  end

  describe "while not in why run mode" do
    before(:each) do
      Chef::Config[:why_run] = false
    end

    describe "load current resource" do
      it "sets the current enabled status to true if the service is enabled for any run level" do
        status = mock("Status", :exitstatus => 0, :stdout => "" , :stderr => "")
        @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
        chkconfig = mock("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:on  6:off", :stderr => "")
        @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
        @provider.instance_variable_get("@service_missing").should be_false
        @provider.load_current_resource
        @current_resource.enabled.should be_true
      end
  
      it "sets the current enabled status to false if the regex does not match" do
        status = mock("Status", :exitstatus => 0, :stdout => "" , :stderr => "")
        @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
        chkconfig = mock("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:off   6:off", :stderr => "")
        @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
        @provider.instance_variable_get("@service_missing").should be_false
        @provider.load_current_resource.should eql(@current_resource)
        @current_resource.enabled.should be_false
      end
    end
  
    describe "define resource requirements" do
      it_should_behave_like "define_resource_requirements_common"
    
      context "when the service does not exist" do
        before do
          status = mock("Status", :exitstatus => 1, :stdout => "", :stderr => "chef: unrecognized service")
          @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
          chkconfig = mock("Chkconfig", :existatus=> 1, :stdout => "", :stderr => "error reading information on service chef: No such file or directory")
          @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
          @provider.load_current_resource
          @provider.define_resource_requirements
        end

        [ "start", "reload", "restart", "enable" ].each do |action|
          it "should raise an error when the action is #{action}" do
            @provider.action = action
            lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
          end
        end

        [ "stop", "disable" ].each do |action|
          it "should not raise an error when the action is #{action}" do
            @provider.action = action
            lambda { @provider.process_resource_requirements }.should_not raise_error
          end
        end
      end
    end
  end

  describe "while in why run mode" do
    before(:each) do
      Chef::Config[:why_run] = true
    end

    after do
      Chef::Config[:why_run] = false
    end

    describe "define resource requirements" do
      it_should_behave_like "define_resource_requirements_common"

      it "should not raise an error if the service does not exist" do
        status = mock("Status", :exitstatus => 1, :stdout => "", :stderr => "chef: unrecognized service")
        @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
        chkconfig = mock("Chkconfig", :existatus=> 1, :stdout => "", :stderr => "error reading information on service chef: No such file or directory")
        @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
        @provider.load_current_resource
        @provider.define_resource_requirements
        lambda { @provider.process_resource_requirements }.should_not raise_error
      end
    end
  end

  describe "enable_service" do
    it "should call chkconfig to add 'service_name'" do
      @provider.should_receive(:shell_out!).with("/sbin/chkconfig #{@new_resource.service_name} on")
      @provider.enable_service
    end
  end

  describe "disable_service" do
    it "should call chkconfig to del 'service_name'" do
      @provider.should_receive(:shell_out!).with("/sbin/chkconfig #{@new_resource.service_name} off")
      @provider.disable_service
    end
  end

end
