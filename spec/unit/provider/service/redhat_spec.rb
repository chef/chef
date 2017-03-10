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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))
require "ostruct"

shared_examples_for "define_resource_requirements_common" do
  it "should raise an error if /sbin/chkconfig does not exist" do
    allow(File).to receive(:exists?).with("/sbin/chkconfig").and_return(false)
    allow(@provider).to receive(:shell_out).with("/sbin/service chef status").and_raise(Errno::ENOENT)
    allow(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_raise(Errno::ENOENT)
    @provider.load_current_resource
    @provider.define_resource_requirements
    expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
  end

  it "should not raise an error if the service exists but is not added to any runlevels" do
    status = double("Status", :exitstatus => 0, :stdout => "" , :stderr => "")
    expect(@provider).to receive(:shell_out).with("/sbin/service chef status").and_return(status)
    chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "", :stderr => "service chef supports chkconfig, but is not referenced in any runlevel (run 'chkconfig --add chef')")
    expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
    @provider.load_current_resource
    @provider.define_resource_requirements
    expect { @provider.process_resource_requirements }.not_to raise_error
  end
end

describe "Chef::Provider::Service::Redhat" do

  before(:each) do
    @node = Chef::Node.new
    @node.automatic_attrs[:command] = { :ps => "foo" }
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)

    @new_resource = Chef::Resource::Service.new("chef")

    @current_resource = Chef::Resource::Service.new("chef")

    @provider = Chef::Provider::Service::Redhat.new(@new_resource, @run_context)
    @provider.action = :start
    allow(Chef::Resource::Service).to receive(:new).and_return(@current_resource)
    allow(File).to receive(:exists?).with("/sbin/chkconfig").and_return(true)
  end

  describe "while not in why run mode" do
    before(:each) do
      Chef::Config[:why_run] = false
    end

    describe "load current resource" do
      before do
        status = double("Status", :exitstatus => 0, :stdout => "" , :stderr => "")
        allow(@provider).to receive(:shell_out).with("/sbin/service chef status").and_return(status)
      end

      it "sets supports[:status] to true by default" do
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:on  6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        @provider.load_current_resource
        expect(@provider.supports[:status]).to be true
      end

      it "lets the user override supports[:status] in the new_resource" do
        @new_resource.supports( { status: false } )
        @new_resource.pattern "myservice"
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:on  6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        foo_out = double("ps_command", :exitstatus => 0, :stdout => "a line that matches myservice", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("foo").and_return(foo_out)
        expect(@provider.service_missing).to be false
        expect(@provider).not_to receive(:shell_out).with("/sbin/service chef status")
        @provider.load_current_resource
        expect(@provider.supports[:status]).to be false
      end

      it "sets the current enabled status to true if the service is enabled for any run level" do
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:on  6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        @provider.load_current_resource
        expect(@current_resource.enabled).to be true
      end

      it "sets the current enabled status to false if the regex does not match" do
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:off   2:off   3:off   4:off   5:off   6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        expect(@provider.load_current_resource).to eql(@current_resource)
        expect(@current_resource.enabled).to be false
      end

      it "sets the current enabled status to true if the service is enabled at specified run levels" do
        @new_resource.run_levels([1, 2])
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:on   2:on   3:off   4:off   5:off   6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        @provider.load_current_resource
        expect(@current_resource.enabled).to be true
        expect(@provider.current_run_levels).to eql([1, 2])
      end

      it "sets the current enabled status to false if the service is enabled at a run level it should not" do
        @new_resource.run_levels([1, 2])
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:on   2:on   3:on   4:off   5:off   6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        @provider.load_current_resource
        expect(@current_resource.enabled).to be false
        expect(@provider.current_run_levels).to eql([1, 2, 3])
      end

      it "sets the current enabled status to false if the service is not enabled at specified run levels" do
        @new_resource.run_levels([ 2 ])
        chkconfig = double("Chkconfig", :exitstatus => 0, :stdout => "chef    0:off   1:on   2:off   3:off   4:off   5:off   6:off", :stderr => "")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        expect(@provider.service_missing).to be false
        @provider.load_current_resource
        expect(@current_resource.enabled).to be false
        expect(@provider.current_run_levels).to eql([1])
      end
    end

    describe "define resource requirements" do
      it_should_behave_like "define_resource_requirements_common"

      context "when the service does not exist" do
        before do
          status = double("Status", :exitstatus => 1, :stdout => "", :stderr => "chef: unrecognized service")
          expect(@provider).to receive(:shell_out).with("/sbin/service chef status").and_return(status)
          chkconfig = double("Chkconfig", :existatus => 1, :stdout => "", :stderr => "error reading information on service chef: No such file or directory")
          expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
          @provider.load_current_resource
          @provider.define_resource_requirements
        end

        %w{start reload restart enable}.each do |action|
          it "should raise an error when the action is #{action}" do
            @provider.action = action
            expect { @provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
          end
        end

        %w{start reload restart}.each do |action|
          it "should not raise an error when the action is #{action} and init_command is set" do
            @new_resource.init_command("/etc/init.d/chef")
            @provider.action = action
            expect { @provider.process_resource_requirements }.not_to raise_error
          end

          it "should not raise an error when the action is #{action} and #{action}_command is set" do
            @new_resource.send("#{action}_command", "/etc/init.d/chef #{action}")
            @provider.action = action
            expect { @provider.process_resource_requirements }.not_to raise_error
          end
        end

        %w{stop disable}.each do |action|
          it "should not raise an error when the action is #{action}" do
            @provider.action = action
            expect { @provider.process_resource_requirements }.not_to raise_error
          end
        end
      end
    end
  end

  describe "while in why run mode" do
    before(:each) do
      Chef::Config[:why_run] = true
    end

    after do
      Chef::Config[:why_run] = false
    end

    describe "define resource requirements" do
      it_should_behave_like "define_resource_requirements_common"

      it "should not raise an error if the service does not exist" do
        status = double("Status", :exitstatus => 1, :stdout => "", :stderr => "chef: unrecognized service")
        expect(@provider).to receive(:shell_out).with("/sbin/service chef status").and_return(status)
        chkconfig = double("Chkconfig", :existatus => 1, :stdout => "", :stderr => "error reading information on service chef: No such file or directory")
        expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --list chef", :returns => [0, 1]).and_return(chkconfig)
        @provider.load_current_resource
        @provider.define_resource_requirements
        expect { @provider.process_resource_requirements }.not_to raise_error
      end
    end
  end

  describe "enable_service" do
    it "should call chkconfig to add 'service_name'" do
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig #{@new_resource.service_name} on")
      @provider.enable_service
    end

    it "should call chkconfig to add 'service_name' at specified run_levels" do
      allow(@provider).to receive(:run_levels).and_return([1, 2])
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 12 #{@new_resource.service_name} on")
      @provider.enable_service
    end

    it "should call chkconfig to add 'service_name' at specified run_levels when run_levels do not match" do
      allow(@provider).to receive(:run_levels).and_return([1, 2])
      allow(@provider).to receive(:current_run_levels).and_return([1, 3])
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 12 #{@new_resource.service_name} on")
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 3 #{@new_resource.service_name} off")
      @provider.enable_service
    end

    it "should call chkconfig to add 'service_name' at specified run_levels if there is an extra run_level" do
      allow(@provider).to receive(:run_levels).and_return([1, 2])
      allow(@provider).to receive(:current_run_levels).and_return([1, 2, 3])
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 12 #{@new_resource.service_name} on")
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 3 #{@new_resource.service_name} off")
      @provider.enable_service
    end
  end

  describe "disable_service" do
    it "should call chkconfig to del 'service_name'" do
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig #{@new_resource.service_name} off")
      @provider.disable_service
    end

    it "should call chkconfig to del 'service_name' at specified run_levels" do
      allow(@provider).to receive(:run_levels).and_return([1, 2])
      expect(@provider).to receive(:shell_out!).with("/sbin/chkconfig --level 12 #{@new_resource.service_name} off")
      @provider.disable_service
    end
  end

end
