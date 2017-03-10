#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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

describe Chef::Provider::Service::Insserv do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @node.automatic_attrs[:command] = { :ps => "ps -ax" }

    @new_resource = Chef::Resource::Service.new("initgrediant")
    @current_resource = Chef::Resource::Service.new("initgrediant")

    @provider = Chef::Provider::Service::Insserv.new(@new_resource, @run_context)
    @status = double("Process::Status mock", :exitstatus => 0, :stdout => "")
    allow(@provider).to receive(:shell_out!).and_return(@status)
  end

  describe "load_current_resource" do
    describe "when startup links exist" do
      before do
        allow(Dir).to receive(:glob).with("/etc/rc**/S*initgrediant").and_return(["/etc/rc5.d/S18initgrediant", "/etc/rc2.d/S18initgrediant", "/etc/rc4.d/S18initgrediant", "/etc/rc3.d/S18initgrediant"])
      end

      it "sets the current enabled status to true" do
        @provider.load_current_resource
        expect(@provider.current_resource.enabled).to be_truthy
      end
    end

    describe "when startup links do not exist" do
      before do
        allow(Dir).to receive(:glob).with("/etc/rc**/S*initgrediant").and_return([])
      end

      it "sets the current enabled status to false" do
        @provider.load_current_resource
        expect(@provider.current_resource.enabled).to be_falsey
      end
    end

  end

  describe "enable_service" do
    it "should call insserv and create the default links" do
      expect(@provider).to receive(:shell_out!).with("/sbin/insserv -r -f #{@new_resource.service_name}")
      expect(@provider).to receive(:shell_out!).with("/sbin/insserv -d -f #{@new_resource.service_name}")
      @provider.enable_service
    end
  end

  describe "disable_service" do
    it "should call insserv and remove the links" do
      expect(@provider).to receive(:shell_out!).with("/sbin/insserv -r -f #{@new_resource.service_name}")
      @provider.disable_service
    end
  end
end
