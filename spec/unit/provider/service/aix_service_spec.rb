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
    allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
  end

  describe "load current resource" do
    it "should create a current resource with the name of the new resource and determine the status" do
      @status = double("Status", :exitstatus => 0, :stdout => @stdout)
      allow(@provider).to receive(:shell_out!).and_return(@status)

      expect(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
      expect(@current_resource).to receive(:service_name).with("chef")
      expect(@provider).to receive(:determine_current_status!)

      @provider.load_current_resource
    end
  end

  describe "determine current status" do
    context "when the service is active" do
      before do
        @status = double("Status", :exitstatus => 0, :stdout => "chef chef 12345 active\n")
      end

      it "current resource is running" do
        expect(@provider).to receive(:shell_out!).with("lssrc -a | grep -w chef").and_return(@status)
        expect(@provider).to receive(:is_resource_group?).with(["chef chef 12345 active"])

        @provider.load_current_resource
        expect(@current_resource.running).to be_true
      end
    end

    context "when the service is inoprative" do
      before do
        @status = double("Status", :exitstatus => 0, :stdout => "chef chef inoperative\n")
      end

      it "current resource is not running" do
        expect(@provider).to receive(:shell_out!).with("lssrc -a | grep -w chef").and_return(@status)
        expect(@provider).to receive(:is_resource_group?).with(["chef chef inoperative"])

        @provider.load_current_resource
        expect(@current_resource.running).to be_false
      end
    end
  end

  describe "is resource group" do
    context "when there are mutiple subsystems associated with group" do
      before do
        @status = double("Status", :exitstatus => 0, :stdout => "chef1 chef 12345 active\nchef2 chef 12334 active\nchef3 chef inoperative")
      end

      it "service is a group" do
        expect(@provider).to receive(:shell_out!).with("lssrc -a | grep -w chef").and_return(@status)
        @provider.load_current_resource
        expect(@provider.instance_eval("@is_resource_group")).to be_true
      end
    end

    context "when there is a single subsystem in the group" do
      before do
        @status = double("Status", :exitstatus => 0, :stdout => "chef1 chef inoperative\n")
      end

      it "service is a group" do
        expect(@provider).to receive(:shell_out!).with("lssrc -a | grep -w chef").and_return(@status)
        @provider.load_current_resource
        expect(@provider.instance_eval("@is_resource_group")).to be_true
      end
    end

    context "when there service is a subsytem" do
      before do
        @status = double("Status", :exitstatus => 0, :stdout => "chef chef123 inoperative\n")
      end

      it "service is a subsystem" do
        expect(@provider).to receive(:shell_out!).with("lssrc -a | grep -w chef").and_return(@status)
        @provider.load_current_resource
        expect(@provider.instance_eval("@is_resource_group")).to be_false
      end
    end
  end

  describe "when starting the service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the start command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      expect(@provider).to receive(:shell_out!).with("startsrc -g #{@new_resource.service_name}")

      @provider.start_service
    end

    it "should call the start command for subsystem" do
      expect(@provider).to receive(:shell_out!).with("startsrc -s #{@new_resource.service_name}")

      @provider.start_service
    end
  end

  describe "when stopping a service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the stop command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      expect(@provider).to receive(:shell_out!).with("stopsrc -g #{@new_resource.service_name}")

      @provider.stop_service
    end

    it "should call the stop command for subsystem" do
      expect(@provider).to receive(:shell_out!).with("stopsrc -s #{@new_resource.service_name}")

      @provider.stop_service
    end
  end

  describe "when reloading a service" do
    before do
      @new_resource.service_name "apache"
    end

    it "should call the reload command for groups" do
      @provider.instance_eval('@is_resource_group = true')
      expect(@provider).to receive(:shell_out!).with("refresh -g #{@new_resource.service_name}")

      @provider.reload_service
    end

    it "should call the reload command for subsystem" do
      expect(@provider).to receive(:shell_out!).with("refresh -s #{@new_resource.service_name}")

      @provider.reload_service
    end
  end

  describe "when restarting the service" do
    it "should call stop service followed by start service" do
      expect(@provider).to receive(:stop_service)
      expect(@provider).to receive(:start_service)

      @provider.restart_service
    end
  end
end

