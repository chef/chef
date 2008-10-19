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

describe Chef::Provider::Service::Init, "load_current_resource" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :running => false
    )
    @provider = Chef::Provider::Service::Init.new(@node, @new_resource)
    Chef::Resource::Service.stub!(:new).and_return(@current_resource)

    @status = mock("Status", :exitstatus => 0)
    @provider.stub!(:popen4).and_return(@status)

    @stdin = mock("STDIN", :null_object => true)
    @stdout = mock("STDOUT", :null_object => true)
    @stdout.stub!(:each).and_yield("aj        7842  5057  0 21:26 pts/2    00:00:06 vi init.rb").
                         and_yield("aj        7903  5016  0 21:26 pts/5    00:00:00 /bin/bash").
                         and_yield("aj        8119  6041  0 21:34 pts/3    00:00:03 vi init_service_spec.rb")
    @stderr = mock("STDERR", :null_object => true)
    @pid = mock("PID", :null_object => true)
    
    @node = mock("Node", :null_object => true)
  end
  
  it "should create a current resource with the name of the new resource" do
    Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
    @provider.load_current_resource
  end

  it "should set the current resources service name to the new resources service name" do
    @current_resource.should_receive(:service_name).with(@new_resource.service_name)
    @provider.load_current_resource
  end

  it "should run /etc/init.d/service_name status if the service supports it" do
    @new_resource.stub!(:supports).and_return({:status => true})
    @provider.should_receive(:run_command).with({:command => "/etc/init.d/#{@current_resource.service_name} status"})
    @provider.load_current_resource
  end
  
  it "should set running to true if the the status command returns 0" do
    @new_resource.stub!(:supports).and_return({:status => true})
    @provider.stub!(:run_command).with({:command => "/etc/init.d/#{@current_resource.service_name} status"}).and_return(0)
    @current_resource.should_recieve(:running).with(true)
    @provider.load_current_resource
  end

  it "should run the services status command if one has been specified" do
    @new_resource.stub!(:supports).and_return({:status => false})
    @new_resource.stub!(:status_command).and_return("/etc/init.d/chefhasmonkeypants status")
    @provider.should_receive(:run_command).with({:command => "/etc/init.d/chefhasmonkeypants status"})
    @provider.load_current_resource
  end
  
  it "should set running to true if the services status command returns 0" do
    @new_resource.stub!(:supports).and_return({:status => false})
    @new_resource.stub!(:status_command).and_return("/etc/init.d/chefhasmonkeypants status")
    @provider.stub!(:run_command).with({:command => "/etc/init.d/chefhasmonkeypants status"}).and_return(0)
    @current_resource.should_receive(:running).with(true)
    @provider.load_current_resource
  end

  it "should set the pattern to the services name if a pattern hasn't been specified"

  it "should raise an exception if the node doesn't have a 'ps' / :ps attribute"

  it "should run the node's ps command"

  it "should close stdin on the ps command"

  it "should read stdout on the ps command"

  it "should raise an exception if ps fails"

  it "should return the current resource"

end
