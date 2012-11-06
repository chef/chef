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

require 'spec_helper'

describe Chef::Provider::Service do
  before do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Service.new("chef")
    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service.new(@new_resource, @run_context)
    @provider.current_resource = @current_resource
    @provider.stub!(:load_current_resource)
  end

  describe "when enabling the service" do
    it "should enable the service if disabled and set the resource as updated" do
      @current_resource.enabled(false)
      @provider.should_receive(:enable_service).and_return(true)
      @provider.action_enable
      @provider.set_updated_status
      @provider.new_resource.should be_updated
    end

    it "should not enable the service if already enabled" do
      @current_resource.enabled(true)
      @provider.should_not_receive(:enable_service)
      @provider.action_enable
      @provider.set_updated_status
      @provider.new_resource.should_not be_updated
    end
  end


  describe "when disabling the service" do
    it "should disable the service if enabled and set the resource as updated" do
      @current_resource.stub!(:enabled).and_return(true)
      @provider.should_receive(:disable_service).and_return(true)
      @provider.run_action(:disable)
      @provider.new_resource.should be_updated
    end

    it "should not disable the service if already disabled" do
      @current_resource.stub!(:enabled).and_return(false)
      @provider.should_not_receive(:disable_service).and_return(true)
      @provider.run_action(:disable)
      @provider.new_resource.should_not be_updated
    end
  end

  describe "action_start" do
    it "should start the service if it isn't running and set the resource as updated" do
      @current_resource.running(false)
      @provider.should_receive(:start_service).with.and_return(true)
      @provider.run_action(:start)
      @provider.new_resource.should be_updated
    end

    it "should not start the service if already running" do
      @current_resource.running(true)
      @provider.should_not_receive(:start_service)
      @provider.run_action(:start)
      @provider.new_resource.should_not be_updated
    end
  end

  describe "action_stop" do
    it "should stop the service if it is running and set the resource as updated" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_receive(:stop_service).and_return(true)
      @provider.run_action(:stop)
      @provider.new_resource.should be_updated
    end

    it "should not stop the service if it's already stopped" do
      @current_resource.stub!(:running).and_return(false)
      @provider.should_not_receive(:stop_service).and_return(true)
      @provider.run_action(:stop)
      @provider.new_resource.should_not be_updated
    end
  end

  describe "action_restart" do
    before do
      @current_resource.supports(:restart => true)
    end

    it "should restart the service if it's supported and set the resource as updated" do
      @provider.should_receive(:restart_service).and_return(true)
      @provider.run_action(:restart)
      @provider.new_resource.should be_updated
    end

    it "should restart the service even if it isn't running and set the resource as updated" do
      @current_resource.stub!(:running).and_return(false)
      @provider.should_receive(:restart_service).and_return(true)
      @provider.run_action(:restart)
      @provider.new_resource.should be_updated
    end
  end

  describe "action_reload" do
    before do
      @new_resource.supports(:reload => true)
    end

    it "should raise an exception if reload isn't supported" do
      @new_resource.supports(:reload => false)
      @new_resource.stub!(:reload_command).and_return(false)
      lambda { @provider.run_action(:reload) }.should raise_error(Chef::Exceptions::UnsupportedAction)
    end

    it "should reload the service if it is running and set the resource as updated" do
      @current_resource.stub!(:running).and_return(true)
      @provider.should_receive(:reload_service).and_return(true)
      @provider.run_action(:reload)
      @provider.new_resource.should be_updated
    end

    it "should not reload the service if it's stopped" do
      @current_resource.stub!(:running).and_return(false)
      @provider.should_not_receive(:reload_service).and_return(true)
      @provider.run_action(:stop)
      @provider.new_resource.should_not be_updated
    end
  end

  it "delegates enable_service to subclasses" do
    lambda { @provider.enable_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "delegates disable_service to subclasses" do
    lambda { @provider.disable_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "delegates start_service to subclasses" do
    lambda { @provider.start_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "delegates stop_service to subclasses" do
    lambda { @provider.stop_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "delegates restart_service to subclasses" do
    lambda { @provider.restart_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end

  it "delegates reload_service to subclasses" do
    lambda { @provider.reload_service }.should raise_error(Chef::Exceptions::UnsupportedAction)
  end
end
