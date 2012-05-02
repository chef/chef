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

describe "load_current_resource" do
  before(:each) do
    @node = Chef::Node.new
    @node[:command] = {:ps => 'foo'}
    @console_ui = Chef::ConsoleUI.new
    @run_context = Chef::RunContext.new(@node, {}, @console_ui)

    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Redhat.new(@new_resource, @run_context)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    File.stub!(:exists?).and_return(true)
  end

  it "should raise an error if /sbin/chkconfig does not exist" do
    ::File.should_receive(:exists?).with("/sbin/chkconfig").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "sets the current enabled status to true if the service is enabled for any run level" do
    chkconfig = OpenStruct.new(:stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:on   6:off")
    status = mock("Status", :exitstatus => 0, :stdout => chkconfig)
    @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
    @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
    @provider.load_current_resource
    @current_resource.enabled.should be_true
  end

  it "sets the current enabled status to false if the regex does not match" do
    chkconfig = OpenStruct.new(:stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:off   6:off")
    status = mock("Status", :exitstatus => 0, :stdout => chkconfig)
    @provider.should_receive(:shell_out).with("/sbin/service chef status").and_return(status)
    @provider.should_receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0,1]).and_return(chkconfig)
    @provider.load_current_resource.should eql(@current_resource)
    @current_resource.enabled.should be_false
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
