#
# Author:: Kaustubh <kaustubh@clogeny.com>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::Provider::Service::Aix do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Aix.new(@new_resource, @run_context)
    Chef::Resource::Service.stub(:new).and_return(@current_resource)
  end

  describe "load current resource" do
    it "should create a current resource with the name of the new resource and determine the status" do
      @status = double("Status", :exitstatus => 0, :stdout => @stdout)
      @provider.stub(:shell_out!).and_return(@status)

      Chef::Resource::Service.should_receive(:new).and_return(@current_resource)
      @current_resource.should_receive(:service_name).with("chef")
      @provider.should_receive(:determine_current_status!)
      @provider.should_receive(:is_resource_group?)

      @provider.load_current_resource
    end

  end

  describe "when starting the service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the start command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      @provider.should_receive(:shell_out!).with("startsrc -g #{@new_resource.service_name}")

      @provider.start_service
    end

    it "should call the start command for subsystem" do
      @provider.should_receive(:shell_out!).with("startsrc -s #{@new_resource.service_name}")

      @provider.start_service
    end
  end

  describe "when stopping a service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the stop command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      @provider.should_receive(:shell_out!).with("stopsrc -g #{@new_resource.service_name}")

      @provider.stop_service
    end

    it "should call the stop command for subsystem" do
      @provider.should_receive(:shell_out!).with("stopsrc -s #{@new_resource.service_name}")

      @provider.stop_service
    end
  end

  describe "when reloading a service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the reload command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      @provider.should_receive(:shell_out!).with("refresh -g #{@new_resource.service_name}")

      @provider.reload_service
    end

    it "should call the reload command for subsystem" do
      @provider.should_receive(:shell_out!).with("refresh -s #{@new_resource.service_name}")

      @provider.reload_service
    end
  end

  describe "when restarting the service" do
    it "should call stop service followed by start service" do
      @provider.should_receive(:stop_service)
      @provider.should_receive(:start_service)

      @provider.restart_service
    end
  end
end

