#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Provider::Service, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end
  
  it "should return a Chef::Provider::Service object" do
    provider = Chef::Provider::Service.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Service)
  end  
  
end

describe Chef::Provider::Service, "action_enable" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:enable_service).and_return(true)
  end

  it "should enable the service if disabled and set the resource as updated" do
    @current_resource.stub!(:enabled).and_return(false)
    @provider.should_receive(:enable_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_enable
  end

  it "should not enable the service if already enabled" do
    @current_resource.stub!(:enabled).and_return(true)
    @provider.should_not_receive(:enable_service).and_return(true)
    @provider.new_resource.should_not_receive(:updated=).with(true)
    @provider.action_enable
  end

end

describe Chef::Provider::Service, "action_disable" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:disable_service).and_return(true)
  end

  it "should disable the service if enabled and set the resource as updated" do
    @current_resource.stub!(:enabled).and_return(true)
    @provider.should_receive(:disable_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_disable
  end

  it "should not disable the service if already disabled" do
    @current_resource.stub!(:enabled).and_return(false)
    @provider.should_not_receive(:disable_service).and_return(true)
    @provider.new_resource.should_not_receive(:updated=).with(true)
    @provider.action_disable
  end
end

describe Chef::Provider::Service, "action_start" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:start_service).and_return(true)
  end

  it "should start the service if it isn't running and set the resource as updated" do
    @current_resource.stub!(:running).and_return(false)
    @provider.should_receive(:start_service).with.and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_start
  end

  it "should not start the service if already running" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_not_receive(:start_service).and_return(true)
    @provider.new_resource.should_not_receive(:updated=).with(true)
    @provider.action_enable
  end
end

describe Chef::Provider::Service, "action_stop" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:stop_service).and_return(true)
  end

  it "should stop the service if it is running and set the resource as updated" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_receive(:stop_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_stop
  end

  it "should not stop the service if it's already stopped" do
    @current_resource.stub!(:running).and_return(false)
    @provider.should_not_receive(:stop_service).and_return(true)
    @provider.new_resource.should_not_receive(:updated=).with(true)
    @provider.action_stop
  end
end

describe Chef::Provider::Service, "action_restart" do
before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :supports => { :restart => false },
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:restart_service).and_return(true)
    @current_resource.stub!(:supports).and_return({:restart => true})
  end

  it "should restart the service if it's supported and set the resource as updated" do
    @provider.should_receive(:restart_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_restart
  end

  it "should restart the service even if it isn't running and set the resource as updated" do
    @current_resource.stub!(:running).and_return(false)
    @provider.should_receive(:restart_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_restart
  end
end

describe Chef::Provider::Service, "action_reload" do
before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :status_command => false
    )
    @current_resource = mock("Chef::Resource::Service",
      :null_object => true,
      :name => "chef",
      :service_name => "chef",
      :supports => { :reload => false},
      :status_command => false
    )
    @provider = Chef::Provider::Service.new(@node, @new_resource)
    @provider.current_resource = @current_resource
    @provider.stub!(:reload_service).and_return(true)
    @current_resource.stub!(:supports).and_return({:reload => true})
  end

  it "should raise an exception if reload isn't supported" do
    @new_resource.stub!(:supports).and_return({:reload => false})
    @new_resource.stub!(:reload_command).and_return(false)
    lambda { @provider.action_reload }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "should reload the service if it is running and set the resource as updated" do
    @current_resource.stub!(:running).and_return(true)
    @provider.should_receive(:reload_service).and_return(true)
    @provider.new_resource.should_receive(:updated=).with(true)
    @provider.action_reload
  end

  it "should not reload the service if it's stopped" do
    @current_resource.stub!(:running).and_return(false)
    @provider.should_not_receive(:stop_service).and_return(true)
    @provider.new_resource.should_not_receive(:updated=).with(true)
    @provider.action_stop
  end
end

%w{enable disable start stop restart reload}.each do |act|
  act_string = "#{act}_service"

  describe Chef::Provider::Service, act_string do
    before(:each) do
      @node = mock("Chef::Node", :null_object => true)
      @new_resource = mock("Chef::Resource::Service",
        :null_object => true,
        :name => "chef",
        :service_name => "chef",
        :status_command => false
      )
      @current_resource = mock("Chef::Resource::Service",
        :null_object => true,
        :name => "chef",
        :service_name => "chef",
        :status_command => false
      )
      @provider = Chef::Provider::Service.new(@node, @new_resource)
      @provider.current_resource = @current_resource
    end

    it "should raise Chef::Exceptions::UnsupportedAction on an unsupported action" do
      lambda { @provider.send(act_string, @new_resource.name) }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end
  end
end
