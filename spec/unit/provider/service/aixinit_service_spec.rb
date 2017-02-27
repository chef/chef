#
# Author:: kaustubh (<kaustubh@clogeny.com>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "spec_helper"

describe Chef::Provider::Service::AixInit do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = { :ps => "fuuuu" }
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @provider = Chef::Provider::Service::AixInit.new(@new_resource, @run_context)

    @current_resource = Chef::Resource::Service.new("chef")
    @provider.current_resource = @current_resource

    @pid, @stdin, @stdout, @stderr = nil, nil, nil, nil
  end

  describe "load_current_resource" do
    it "sets current resource attributes" do
      expect(@provider).to receive(:set_current_resource_attributes)

      @provider.load_current_resource
    end
  end

  describe "action_enable" do
    shared_examples_for "the service is up to date" do
      it "does not enable the service" do
        expect(@provider).not_to receive(:enable_service)
        @provider.action_enable
        @provider.set_updated_status
        expect(@provider.new_resource).not_to be_updated
      end
    end

    shared_examples_for "the service is not up to date" do
      it "enables the service and sets the resource as updated" do
        expect(@provider).to receive(:enable_service).and_return(true)
        @provider.action_enable
        @provider.set_updated_status
        expect(@provider.new_resource).to be_updated
      end
    end

    context "when the service is disabled" do
      before do
        @current_resource.enabled(false)
      end

      it_behaves_like "the service is not up to date"
    end

    context "when the service is enabled" do
      before do
        @current_resource.enabled(true)
        @current_resource.priority(80)
      end

      context "and the service sets no priority" do
        it_behaves_like "the service is up to date"
      end

      context "and the service requests the same priority as is set" do
        before do
          @new_resource.priority(80)
        end
        it_behaves_like "the service is up to date"
      end

      context "and the service requests a different priority than is set" do
        before do
          @new_resource.priority(20)
        end
        it_behaves_like "the service is not up to date"
      end
    end
  end

  describe "enable_service" do
    before do
      allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).and_return([])
    end

    context "when the service doesn't set a priority" do
      it "creates symlink with status S" do
        expect(@provider).to receive(:create_symlink).with(2, "S", "")

        @provider.enable_service
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        @new_resource.priority(75)
      end

      it "creates a symlink with status S and a priority" do
        expect(@provider).to receive(:create_symlink).with(2, "S", 75)

        @provider.enable_service
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        priority = { 2 => [:start, 20], 3 => [:stop, 10] }
        @new_resource.priority(priority)
      end

      it "create symlink with status start (S) or stop (K) and a priority " do
        expect(@provider).to receive(:create_symlink).with(2, "S", 20)
        expect(@provider).to receive(:create_symlink).with(3, "K", 10)

        @provider.enable_service
      end
    end
  end

  describe "disable_service" do
    before do
      allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).and_return([])
    end

    context "when the service doesn't set a priority" do
      it "creates symlinks with status stop (K)" do
        expect(@provider).to receive(:create_symlink).with(2, "K", "")

        @provider.disable_service
      end
    end

    context "when the service sets a simple priority (integer)" do
      before do
        @new_resource.priority(75)
      end

      it "create symlink with status stop (k) and a priority " do
        expect(@provider).to receive(:create_symlink).with(2, "K", 25)

        @provider.disable_service
      end
    end

    context "when the service sets complex priorities (hash)" do
      before do
        @priority = { 2 => [:start, 20], 3 => [:stop, 10] }
        @new_resource.priority(@priority)
      end

      it "create symlink with status stop (k) and a priority " do
        expect(@provider).to receive(:create_symlink).with(3, "K", 90)

        @provider.disable_service
      end
    end
  end

  describe "set_current_resource_attributes" do
    context "when rc2.d contains only start script" do
      before do
        files = ["/etc/rc.d/rc2.d/S20apache"]

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]chef"]).and_return(files)
      end

      it "the service is enabled" do
        expect(@provider.current_resource).to receive(:enabled).with(true)
        expect(@provider.current_resource).to receive(:priority).with(20)

        @provider.set_current_resource_attributes
      end
    end

    context "when rc2.d contains only stop script" do
      before do
        files = ["/etc/rc.d/rc2.d/K20apache"]
        @priority = { 2 => [:stop, 20] }

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]chef"]).and_return(files)
      end
      it "the service is not enabled" do
        expect(@provider.current_resource).to receive(:enabled).with(false)
        expect(@provider.current_resource).to receive(:priority).with(@priority)

        @provider.set_current_resource_attributes
      end
    end

    context "when rc2.d contains both start and stop scripts" do
      before do
        @files = ["/etc/rc.d/rc2.d/S20apache", "/etc/rc.d/rc2.d/K80apache"]
        # FIXME: this is clearly buggy the duplicated keys do not work
        #@priority = {2 => [:start, 20], 2 => [:stop, 80]}
        @priority = { 2 => [:stop, 80] }

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]chef"]).and_return(@files)
      end
      it "the service is enabled" do
        expect(@current_resource).to receive(:enabled).with(true)
        expect(@current_resource).to receive(:priority).with(@priority)

        @provider.set_current_resource_attributes
      end
    end

    context "when rc2.d contains only start script (without priority)" do
      before do
        files = ["/etc/rc.d/rc2.d/Sapache"]

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).and_return(files)
      end

      it "the service is enabled" do
        expect(@provider.current_resource).to receive(:enabled).with(true)
        expect(@provider.current_resource).to receive(:priority).with("")

        @provider.set_current_resource_attributes
      end
    end

    context "when rc2.d contains only stop script (without priority)" do
      before do
        files = ["/etc/rc.d/rc2.d/Kapache"]
        @priority = { 2 => [:stop, ""] }

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).and_return(files)
      end
      it "the service is not enabled" do
        expect(@provider.current_resource).to receive(:enabled).with(false)
        expect(@provider.current_resource).to receive(:priority).with(@priority)

        @provider.set_current_resource_attributes
      end
    end

    context "when rc2.d contains both start and stop scripts" do
      before do
        files = ["/etc/rc.d/rc2.d/Sapache", "/etc/rc.d/rc2.d/Kapache"]
        # FIXME: this is clearly buggy the duplicated keys do not work
        #@priority = {2 => [:start, ''], 2 => [:stop, '']}
        @priority = { 2 => [:stop, ""] }

        allow(Dir).to receive(:glob).with(["/etc/rc.d/rc2.d/[SK][0-9][0-9]#{@new_resource.service_name}", "/etc/rc.d/rc2.d/[SK]#{@new_resource.service_name}"]).and_return(files)
      end
      it "the service is enabled" do
        expect(@current_resource).to receive(:enabled).with(true)
        expect(@current_resource).to receive(:priority).with(@priority)

        @provider.set_current_resource_attributes
      end
    end
  end
end
