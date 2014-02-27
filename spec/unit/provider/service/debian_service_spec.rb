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

require 'spec_helper'

describe Chef::Provider::Service::Debian do
  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = {:ps => 'fuuuu'}
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")
    @provider = Chef::Provider::Service::Debian.new(@new_resource, @run_context)

    @current_resource = Chef::Resource::Service.new("chef")
    @provider.current_resource = @current_resource

    @pid, @stdin, @stdout, @stderr = nil, nil, nil, nil
  end

  describe "load_current_resource" do
    it "ensures /usr/sbin/update-rc.d is available" do
      File.should_receive(:exists?).with("/usr/sbin/update-rc.d") .and_return(false)

      @provider.define_resource_requirements
      lambda {
        @provider.process_resource_requirements
      }.should raise_error(Chef::Exceptions::Service)
    end

    context "when update-rc.d shows init linked to rc*.d/" do
      before do
        @provider.stub(:assert_update_rcd_available)

        result = <<-UPDATE_RC_D_SUCCESS
  Removing any system startup links for /etc/init.d/chef ...
    /etc/rc0.d/K20chef
    /etc/rc1.d/K20chef
    /etc/rc2.d/S20chef
    /etc/rc3.d/S20chef
    /etc/rc4.d/S20chef
    /etc/rc5.d/S20chef
    /etc/rc6.d/K20chef
        UPDATE_RC_D_SUCCESS

        @stdout = StringIO.new(result)
        @stderr = StringIO.new
        @status = double("Status", :exitstatus => 0, :stdout => @stdout)
        @provider.stub(:shell_out!).and_return(@status)
        @provider.stub(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "says the service is enabled" do
        @provider.service_currently_enabled?(@provider.get_priority).should be_true
      end

      it "stores the 'enabled' state" do
        Chef::Resource::Service.stub(:new).and_return(@current_resource)
        @provider.load_current_resource.should equal(@current_resource)
        @current_resource.enabled.should be_true
      end
    end

    context "when update-rc.d shows init isn't linked to rc*.d/" do
      before do
        @provider.stub(:assert_update_rcd_available)
        @status = double("Status", :exitstatus => 0)
        @stdout = StringIO.new(
          " Removing any system startup links for /etc/init.d/chef ...")
        @stderr = StringIO.new
        @status = double("Status", :exitstatus => 0, :stdout => @stdout)
        @provider.stub(:shell_out!).and_return(@status)
        @provider.stub(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
      end

      it "says the service is disabled" do
        @provider.service_currently_enabled?(@provider.get_priority).should be_false
      end

      it "stores the 'disabled' state" do
        Chef::Resource::Service.stub(:new).and_return(@current_resource)
        @provider.load_current_resource.should equal(@current_resource)
        @current_resource.enabled.should be_false
      end
    end

    context "when update-rc.d fails" do
      before do
        @status = double("Status", :exitstatus => -1)
        @provider.stub(:popen4).and_return(@status)
      end

      it "raises an error" do
        @provider.define_resource_requirements
        lambda {
          @provider.process_resource_requirements
        }.should raise_error(Chef::Exceptions::Service)
      end
    end

    {"Debian/Lenny and older" => {
        "linked" => {
          "stdout" => <<-STDOUT,
 Removing any system startup links for /etc/init.d/chef ...
     /etc/rc0.d/K20chef
     /etc/rc1.d/K20chef
     /etc/rc2.d/S20chef
     /etc/rc3.d/S20chef
     /etc/rc4.d/S20chef
     /etc/rc5.d/S20chef
     /etc/rc6.d/K20chef
          STDOUT
          "stderr" => "",
          "priorities" => {
            "0"=>[:stop, "20"],
            "1"=>[:stop, "20"],
            "2"=>[:start, "20"],
            "3"=>[:start, "20"],
            "4"=>[:start, "20"],
            "5"=>[:start, "20"],
            "6"=>[:stop, "20"]
          }
        },
        "not linked" => {
          "stdout" => " Removing any system startup links for /etc/init.d/chef ...",
          "stderr" => ""
        },
      },
      "Debian/Squeeze and earlier" => {
        "linked" => {
          "stdout" => "update-rc.d: using dependency based boot sequencing",
          "stderr" => <<-STDERR,
insserv: remove service /etc/init.d/../rc0.d/K20chef-client
  insserv: remove service /etc/init.d/../rc1.d/K20chef-client
  insserv: remove service /etc/init.d/../rc2.d/S20chef-client
  insserv: remove service /etc/init.d/../rc3.d/S20chef-client
  insserv: remove service /etc/init.d/../rc4.d/S20chef-client
  insserv: remove service /etc/init.d/../rc5.d/S20chef-client
  insserv: remove service /etc/init.d/../rc6.d/K20chef-client
  insserv: dryrun, not creating .depend.boot, .depend.start, and .depend.stop
          STDERR
          "priorities" => {
            "0"=>[:stop, "20"],
            "1"=>[:stop, "20"],
            "2"=>[:start, "20"],
            "3"=>[:start, "20"],
            "4"=>[:start, "20"],
            "5"=>[:start, "20"],
            "6"=>[:stop, "20"]
          }
        },
        "not linked" => {
          "stdout" => "update-rc.d: using dependency based boot sequencing",
          "stderr" => ""
        }
      },
      "Debian/Wheezy and earlier, a service only starting at run level S" => {
        "linked" => {
          "stdout" => "",
          "stderr" => <<-STDERR,
insserv: remove service /etc/init.d/../rc0.d/K06rpcbind
insserv: remove service /etc/init.d/../rc1.d/K06rpcbind
insserv: remove service /etc/init.d/../rc6.d/K06rpcbind
insserv: remove service /etc/init.d/../rcS.d/S13rpcbind
insserv: dryrun, not creating .depend.boot, .depend.start, and .depend.stop
          STDERR
          "priorities" => {
            "0"=>[:stop, "06"],
            "1"=>[:stop, "06"],
            "6"=>[:stop, "06"],
            "S"=>[:start, "13"]
          }
        },
        "not linked" => {
          "stdout" => "",
          "stderr" => "insserv: dryrun, not creating .depend.boot, .depend.start, and .depend.stop"
        }
      }
    }.each do |model, expected_results|
      context "on #{model}" do
        context "when update-rc.d shows init linked to rc*.d/" do
          before do
            @provider.stub(:assert_update_rcd_available)

            @stdout = StringIO.new(expected_results["linked"]["stdout"])
            @stderr = StringIO.new(expected_results["linked"]["stderr"])
            @status = double("Status", :exitstatus => 0, :stdout => @stdout)
            @provider.stub(:shell_out!).and_return(@status)
            @provider.stub(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
          end

          it "says the service is enabled" do
            @provider.service_currently_enabled?(@provider.get_priority).should be_true
          end

          it "stores the 'enabled' state" do
            Chef::Resource::Service.stub(:new).and_return(@current_resource)
            @provider.load_current_resource.should equal(@current_resource)
            @current_resource.enabled.should be_true
          end

          it "stores the start/stop priorities of the service" do
            @provider.load_current_resource
            @provider.current_resource.priority.should == expected_results["linked"]["priorities"]
          end
        end

        context "when update-rc.d shows init isn't linked to rc*.d/" do
          before do
            @provider.stub(:assert_update_rcd_available)
            @stdout = StringIO.new(expected_results["not linked"]["stdout"])
            @stderr = StringIO.new(expected_results["not linked"]["stderr"])
            @status = double("Status", :exitstatus => 0, :stdout => @stdout)
            @provider.stub(:shell_out!).and_return(@status)
            @provider.stub(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
          end

          it "says the service is disabled" do
            @provider.service_currently_enabled?(@provider.get_priority).should be_false
          end

          it "stores the 'disabled' state" do
            Chef::Resource::Service.stub(:new).and_return(@current_resource)
            @provider.load_current_resource.should equal(@current_resource)
            @current_resource.enabled.should be_false
          end
        end
      end
    end

  end

  describe "action_enable" do
    shared_examples_for "the service is up to date" do
      it "does not enable the service" do
        @provider.should_not_receive(:enable_service)
        @provider.action_enable
        @provider.set_updated_status
        @provider.new_resource.should_not be_updated
      end
    end

    shared_examples_for "the service is not up to date" do
      it "enables the service and sets the resource as updated" do
        @provider.should_receive(:enable_service).and_return(true)
        @provider.action_enable
        @provider.set_updated_status
        @provider.new_resource.should be_updated
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
      provider.should_receive(:run_command).with({:command => command})
    end
  end

  describe "enable_service" do
    let(:service_name) { @new_resource.service_name }
    context "when the service doesn't set a priority" do
      it "calls update-rc.d 'service_name' defaults" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d #{service_name} defaults"
        ])
        @provider.enable_service
      end
    end

    context "when the service sets a simple priority" do
      before do
        @new_resource.priority(75)
      end

      it "calls update-rc.d 'service_name' defaults" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d #{service_name} defaults 75 25"
        ])
        @provider.enable_service
      end
    end

    context "when the service sets complex priorities" do
      before do
        @new_resource.priority(2 => [:start, 20], 3 => [:stop, 55])
      end

      it "calls update-rc.d 'service_name' with those priorities" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d #{service_name} start 20 2 . stop 55 3 . "
        ])
        @provider.enable_service
      end
    end
  end

  describe "disable_service" do
    let(:service_name) { @new_resource.service_name }
    context "when the service doesn't set a priority" do
      it "calls update-rc.d -f 'service_name' remove + stop with default priority" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d -f #{service_name} stop 80 2 3 4 5 ."
        ])
        @provider.disable_service
      end
    end

    context "when the service sets a simple priority" do
      before do
        @new_resource.priority(75)
      end

      it "calls update-rc.d -f 'service_name' remove + stop with the specified priority" do
        expect_commands(@provider, [
          "/usr/sbin/update-rc.d -f #{service_name} remove",
          "/usr/sbin/update-rc.d -f #{service_name} stop #{100 - @new_resource.priority} 2 3 4 5 ."
        ])
        @provider.disable_service
      end
    end
  end
end
