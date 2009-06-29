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

describe Chef::Provider::Service::Redhat, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false,
      :status_command => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false,
      :status_command => false
    )

    @provider = Chef::Provider::Service::Redhat.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
    File.stub!(:exists?).and_return(true)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)
    @provider.should_receive(:run_command).with(:command => "/sbin/service chef status")
    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout_string = "chef    0:off   1:off   2:off   3:off   4:off   5:off   6:off"
    @stdout.stub!(:gets).and_return(@stdout_string)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
  end

  it "should raise an error if /sbin/chkconfig does not exist" do
    File.should_receive(:exists?).with("/sbin/chkconfig").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end

  it "should popen4 '/sbin/chkconfig --list service_name'" do
    @provider.should_receive(:popen4).with("/sbin/chkconfig --list chef").and_return(@status)
    @provider.load_current_resource
  end

  it "should read the stdout of the chkconfig command" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @stdout.should_receive(:gets).once.and_return(@stdout_string)
    @provider.load_current_resource
  end

  it "should set enabled to true if the regex matches" do
    @stdout.stub!(:gets).and_return("chef    0:off   1:off   2:on   3:on   4:on   5:on   6:off")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:enabled).with(true)
    @provider.load_current_resource
  end

  it "should set enabled to false if the regex does not match" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:enabled).with(false)
    @provider.load_current_resource
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end
end

describe Chef::Provider::Service::Redhat, "enable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )

    @provider = Chef::Provider::Service::Redhat.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call chkconfig to add 'service_name'" do
    @provider.should_receive(:run_command).with({:command => "/sbin/chkconfig #{@new_resource.service_name} on"})
    @provider.enable_service()
  end
end

describe Chef::Provider::Service::Redhat, "disable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Redhat",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )

    @provider = Chef::Provider::Service::Redhat.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call chkconfig to del 'service_name'" do
    @provider.should_receive(:run_command).with({:command => "/sbin/chkconfig #{@new_resource.service_name} off"})
    @provider.disable_service()
  end
end
