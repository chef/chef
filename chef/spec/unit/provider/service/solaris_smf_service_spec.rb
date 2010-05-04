#
# Author:: Toomas Pelberg (<toomasp@gmx.net>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

describe Chef::Provider::Service::Solaris, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @provider = Chef::Provider::Service::Solaris.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    @stdout_string = "state disabled"
    @stdout.stub!(:gets).and_return(@stdout_string)
  end

  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should return the current resource" do
    @provider.load_current_resource.should eql(@current_resource)
  end 

  it "should raise an error if /bin/svcs does not exist" do
    File.should_receive(:exists?).with("/bin/svcs").and_return(false)
    lambda { @provider.load_current_resource }.should raise_error(Chef::Exceptions::Service)
  end 

  it "should popen4 '/bin/svcs -l service_name'" do
    @provider.should_receive(:popen4).with("/bin/svcs -l chef").and_return(@status)
    @provider.load_current_resource
  end

  it "should mark service as not running" do
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:running).with(false)
    @provider.load_current_resource
  end

  it "should mark service as running" do
    @stdout.stub!(:each).and_yield("state online")
    @provider.stub!(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
    @current_resource.should_receive(:running).with(true)
    @provider.load_current_resource
  end

end

describe Chef::Provider::Service::Solaris, "enable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @provider = Chef::Provider::Service::Solaris.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call svcadm enable chef" do
    @provider.should_receive(:run_command).with({:command => "/usr/sbin/svcadm enable chef"})
    @provider.load_current_resource()
    @provider.enable_service()
  end

  it "should call svcadm enable chef for start_service" do
    @provider.should_receive(:run_command).with({:command => "/usr/sbin/svcadm enable chef"})
    @provider.load_current_resource()
    @provider.start_service()
  end

end


describe Chef::Provider::Service::Solaris, "disable_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @provider = Chef::Provider::Service::Solaris.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call svcadm disable chef" do
    @provider.should_receive(:run_command).with({:command => "/usr/sbin/svcadm disable chef"})
    @provider.load_current_resource()
    @provider.disable_service()
  end

  it "should call svcadm disable chef for stop_service" do
    @provider.should_receive(:run_command).with({:command => "/usr/sbin/svcadm disable chef"})
    @provider.load_current_resource()
    @provider.stop_service()
  end

end

describe Chef::Provider::Service::Solaris, "reload_service" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)

    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :enabled => false
    )

    @provider = Chef::Provider::Service::Solaris.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)
  end

  it "should call svcadm refresh chef" do
    @provider.should_receive(:run_command).with({:command => "/usr/sbin/svcadm refresh chef"})
    @provider.load_current_resource()
    @provider.reload_service()
  end

end
