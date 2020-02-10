#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright 2008-2016, HJK Solutions, LLC
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

describe Chef::Provider::Service::Debian do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = { ps: "fuuuu" }
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @provider = Chef::Provider::Service::Debian.new(@new_resource, @run_context)

    @current_resource = Chef::Resource::Service.new("chef")
    @provider.current_resource = @current_resource

    @pid, @stdin, @stdout, @stderr = nil, nil, nil, nil
    allow(File).to receive(:exist?).with("/etc/init.d/chef").and_return true
  end

  let(:init_lines) do
    [
      "### BEGIN INIT INFO",
      "# Required-Start:    hostname $local_fs",
      "# Default-Start:     2 3 4 5",
      "# Default-Stop: 0 1 6",
      "### END INIT INFO",
    ]
  end

  describe "load_current_resource" do
    it "ensures /usr/sbin/update-rc.d is available" do
      expect(File).to receive(:exists?).with("/usr/sbin/update-rc.d") .and_return(false)

      @provider.define_resource_requirements
      expect do
        @provider.process_resource_requirements
      end.to raise_error(Chef::Exceptions::Service)
    end

    context "when update-rc.d shows init linked to rc*.d/" do
      before do
        allow(@provider).to receive(:assert_update_rcd_available)
        allow(File).to receive(:readlines).with("/etc/init.d/chef").and_return(init_lines)

        [0, 1, 6].each do |stop|
          allow(Dir).to receive(:glob).with("/etc/rc#{stop}.d/[SK][0-9][0-9]chef").and_return(["/etc/rc#{stop}.d/K20chef"])
        end
        [2, 3, 4, 5].each do |start|
          allow(Dir).to receive(:glob).with("/etc/rc#{start}.d/[SK][0-9][0-9]chef").and_return(["/etc/rc#{start}.d/S20chef"])
        end
      end

      it "says the service is enabled" do
        expect(@provider.service_currently_enabled?(@provider.get_priority)).to be_truthy
      end

      it "stores the 'enabled' state" do
        allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
        expect(@provider.load_current_resource).to equal(@current_resource)
        expect(@current_resource.enabled).to be_truthy
      end

      it "stores the start/stop priorities of the service" do
        @provider.load_current_resource
        expect(@provider.current_resource.priority).to eq(
          {
            "2" => [:start, "20"],
            "3" => [:start, "20"],
            "4" => [:start, "20"],
            "5" => [:start, "20"],
            "0" => [:stop, "20"],
            "1" => [:stop, "20"],
            "6" => [:stop, "20"],
          }
        )
      end
    end

    context "when update-rc.d shows init isn't linked to rc*.d/" do
      before do
        allow(@provider).to receive(:assert_update_rcd_available)

        allow(File).to receive(:readlines).with("/etc/init.d/chef").and_return(init_lines)

        [0, 1, 6].each do |stop|
          allow(Dir).to receive(:glob).with("/etc/rc#{stop}.d/[SK][0-9][0-9]chef").and_return([])
        end
        [2, 3, 4, 5].each do |start|
          allow(Dir).to receive(:glob).with("/etc/rc#{start}.d/[SK][0-9][0-9]chef").and_return([])
        end
      end

      it "says the service is disabled" do
        expect(@provider.service_currently_enabled?(@provider.get_priority)).to be_falsey
      end

      it "stores the 'disabled' state" do
        allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
        expect(@provider.load_current_resource).to equal(@current_resource)
        expect(@current_resource.enabled).to be_falsey
      end
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

  def expect_commands(provider, commands)
    commands.each do |command|
      expect(provider).to receive(:shell_out!).with(command)
    end
  end

  describe "enable_service" do
    let(:service_name) { @new_resource.service_name }
    context "when the service doesn't set a priority" do
      it "assumes default priority 20 and calls update-rc.d remove => defaults 20 80" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d #{service_name} defaults 20 80",
        ])
        @provider.enable_service
      end
    end

    context "when the service sets a simple priority 75" do
      before do
        @new_resource.priority(75)
      end

      it "calls update-rc.d remove => defaults 75 25" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d #{service_name} defaults 75 25",
        ])
        @provider.enable_service
      end
    end

    context "when the service sets complex priorities using Hash" do
      before do
        @new_resource.priority(2 => [:start, 20], 3 => [:stop, 55])
      end

      context "when modern update-rc.d is detected" do
        before do
          expect(@provider).to receive(:use_legacy_update_rc_d?).and_return(false)
        end

        it "calls update-rc.d remove => defaults => enable|disable <runlevel>" do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} defaults",
            "/usr/sbin/update-rc.d #{service_name} enable 2",
            "/usr/sbin/update-rc.d #{service_name} disable 3",
          ])
          @provider.enable_service
        end
      end

      context "when legacy update-rc.d is detected" do
        before do
          expect(@provider).to receive(:use_legacy_update_rc_d?).and_return(true)
        end

        it "calls update-rc.d remove => start|stop <priority> <levels> ." do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} start 20 2 . stop 55 3 . ",
          ])
          @provider.disable_service
        end
      end
    end
  end

  describe "disable_service" do
    let(:service_name) { @new_resource.service_name }

    context "when modern update-rc.d is detected" do
      before do
        expect(@provider).to receive(:use_legacy_update_rc_d?).and_return(false)
      end

      context "when the service doesn't set a priority" do
        it "calls update-rc.d remove => defaults => disable" do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} defaults",
            "/usr/sbin/update-rc.d #{service_name} disable",
          ])
          @provider.disable_service
        end
      end

      context "when the service sets a simple priority 75" do
        before do
          @new_resource.priority(75)
        end

        it "ignores priority and calls update-rc.d remove => defaults => disable" do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} defaults",
            "/usr/sbin/update-rc.d #{service_name} disable",
          ])
          @provider.disable_service
        end
      end

      context "when the service sets complex priorities using Hash" do
        before do
          @new_resource.priority(2 => [:start, 20], 3 => [:stop, 55])
        end

        it "ignores priority and calls update-rc.d remove => defaults => enable|disable <runlevel>" do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} defaults",
            "/usr/sbin/update-rc.d #{service_name} enable 2",
            "/usr/sbin/update-rc.d #{service_name} disable 3",
          ])
          @provider.disable_service
        end
      end
    end

    context "when legacy update-rc.d is detected" do
      before do
        expect(@provider).to receive(:use_legacy_update_rc_d?).and_return(true)
      end

      context "when the service doesn't set a priority" do
        it "assumes default priority 20 and calls update-rc.d remove => stop 80 2 3 4 5 ." do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d -f #{service_name} stop 80 2 3 4 5 .",
          ])
          @provider.disable_service
        end
      end

      context "when the service sets a simple priority 75" do
        before do
          @new_resource.priority(75)
        end

        it "reverses priority and calls update-rc.d remove => stop 25 2 3 4 5 ." do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d -f #{service_name} stop #{100 - @new_resource.priority} 2 3 4 5 .",
          ])
          @provider.disable_service
        end
      end

      context "when the service sets complex priorities using Hash" do
        before do
          @new_resource.priority(2 => [:start, 20], 3 => [:stop, 55])
        end

        it "calls update-rc.d remove => start|stop <priority> <levels> ." do
          expect_commands(@provider, [
            "/usr/sbin/update-rc.d -f #{service_name} remove",
            "/usr/sbin/update-rc.d #{service_name} start 20 2 . stop 55 3 . ",
          ])
          @provider.disable_service
        end
      end
    end
  end

  describe "use_legacy_update_rc_d?" do
    let(:dpkg_query_cmd) { "dpkg-query -W --showformat '${Version}' sysv-rc" }

    it "is true when svsv-rc package version < 2.88 is installed" do
      shellout_result = double(stdout: "2.86.ds1-34\n")
      expect(@provider).to receive(:shell_out!).with(dpkg_query_cmd).and_return(shellout_result)
      expect(@provider.use_legacy_update_rc_d?).to eq(true)
    end

    it "is true when sysv-rc is 2.88 and patch level < ('dsf-')42" do
      shellout_result = double(stdout: "2.88.dsf-41\n")
      expect(@provider).to receive(:shell_out!).with(dpkg_query_cmd).and_return(shellout_result)
      expect(@provider.use_legacy_update_rc_d?).to eq(true)
    end

    it "is false when sysv-rc package version >= 2.88 is installed" do
      shellout_result = double(stdout: "2.88dsf-59.9\n")
      expect(@provider).to receive(:shell_out!).with(dpkg_query_cmd).and_return(shellout_result)
      expect(@provider.use_legacy_update_rc_d?).to eq(false)
    end

    it "is false when sysv-rc package is not installed" do
      shellout_result = double(stdout: "\n")
      expect(@provider).to receive(:shell_out!).with(dpkg_query_cmd).and_return(shellout_result)
      expect(@provider.use_legacy_update_rc_d?).to eq(false)
    end
  end
end
