#
# Author:: Igor Afonov <afonov@gmail.com>
# Copyright:: Copyright (c) 2011 Igor Afonov
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

describe Chef::Provider::Service::Macosx do
  describe ".gather_plist_dirs" do
    context "when HOME directory is set" do
      before do
        ENV.stub(:[]).with('HOME').and_return("/User/someuser")
      end

      it "includes users's LaunchAgents folder" do
        described_class.gather_plist_dirs.should include("#{ENV['HOME']}/Library/LaunchAgents")
      end
    end

    context "when HOME directory is not set" do
      before do
        ENV.stub(:[]).with('HOME').and_return(nil)
      end

      it "doesn't include user's LaunchAgents folder" do
        described_class.gather_plist_dirs.should_not include("~/Library/LaunchAgents")
      end
    end
  end

  context "when service name is given as" do
    let(:node) { Chef::Node.new }
    let(:events) {Chef::EventDispatch::Dispatcher.new}
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:provider) { described_class.new(new_resource, run_context) }
    let(:stdout) { StringIO.new }

    ["redis-server", "io.redis.redis-server"].each do |service_name|
      before do
        Dir.stub!(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
        provider.stub!(:shell_out!).
                 with("launchctl list", {:group => 1001, :user => 101}).
                 and_return(mock("ouput", :stdout => stdout))

        File.stub!(:stat).and_return(mock("stat", :gid => 1001, :uid => 101))
      end

      context "#{service_name}" do
        let(:new_resource) { Chef::Resource::Service.new(service_name) }
        let!(:current_resource) { Chef::Resource::Service.new(service_name) }

        describe "#load_current_resource" do
          context "when launchctl returns pid in service list" do
            let(:stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  7777  - io.redis.redis-server
  - - com.lol.stopped-thing
  SVC_LIST

            before do
              provider.load_current_resource
            end

            it "sets resource running state to true" do
              provider.current_resource.running.should be_true
            end

            it "sets resouce enabled state to true" do
              provider.current_resource.enabled.should be_true
            end
          end

          describe "running unsupported actions" do
            before do
              Dir.stub!(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
            end
            it "should throw an exception when enable action is attempted" do
              lambda {provider.run_action(:enable)}.should raise_error(Chef::Exceptions::UnsupportedAction)
            end
            it "should throw an exception when reload action is attempted" do
              lambda {provider.run_action(:reload)}.should raise_error(Chef::Exceptions::UnsupportedAction)
            end
            it "should throw an exception when disable action is attempted" do
              lambda {provider.run_action(:disable)}.should raise_error(Chef::Exceptions::UnsupportedAction)
            end
          end
          context "when launchctl returns empty service pid" do
            let(:stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  - - io.redis.redis-server
  - - com.lol.stopped-thing
  SVC_LIST

            before do
              provider.load_current_resource
            end

            it "sets resource running state to false" do
              provider.current_resource.running.should be_false
            end

            it "sets resouce enabled state to true" do
              provider.current_resource.enabled.should be_true
            end
          end

          context "when launchctl doesn't return service entry at all" do
            let(:stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  - - com.lol.stopped-thing
  SVC_LIST

            it "sets service running state to false" do
              provider.load_current_resource
              provider.current_resource.running.should be_false
            end

            context "and plist for service is not available" do
              before do
                Dir.stub!(:glob).and_return([])
                provider.load_current_resource
              end

              it "sets resouce enabled state to false" do
                provider.current_resource.enabled.should be_false
              end
            end

            context "and plist for service is available" do
              before do
                Dir.stub!(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
                provider.load_current_resource
              end

              it "sets resouce enabled state to true" do
                provider.current_resource.enabled.should be_true
              end
            end

            describe "and several plists match service name" do
              it "throws exception" do
                Dir.stub!(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist",
                                             "/Users/wtf/something.plist"])
                provider.load_current_resource
                provider.define_resource_requirements
                lambda { provider.process_resource_requirements }.should raise_error(Chef::Exceptions::Service)
              end
            end
          end
        end
        describe "#start_service" do
          before do
            Chef::Resource::Service.stub!(:new).and_return(current_resource)
            provider.load_current_resource
            current_resource.stub!(:running).and_return(false)
          end

          it "calls the start command if one is specified and service is not running" do
            new_resource.stub!(:start_command).and_return("cowsay dirty")

            provider.should_receive(:shell_out!).with("cowsay dirty")
            provider.start_service
          end

          it "shows warning message if service is already running" do
            current_resource.stub!(:running).and_return(true)
            Chef::Log.should_receive(:debug).with("service[#{service_name}] already running, not starting")

            provider.start_service
          end

          it "starts service via launchctl if service found" do
            provider.should_receive(:shell_out!).
                     with("launchctl load -w '/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist'",
                           :group => 1001, :user => 101).
                     and_return(0)

            provider.start_service
          end
        end

        describe "#stop_service" do
          before do
            Chef::Resource::Service.stub!(:new).and_return(current_resource)

            provider.load_current_resource
            current_resource.stub!(:running).and_return(true)
          end

          it "calls the stop command if one is specified and service is running" do
            new_resource.stub!(:stop_command).and_return("kill -9 123")

            provider.should_receive(:shell_out!).with("kill -9 123")
            provider.stop_service
          end

          it "shows warning message if service is not running" do
            current_resource.stub!(:running).and_return(false)
            Chef::Log.should_receive(:debug).with("service[#{service_name}] not running, not stopping")

            provider.stop_service
          end

          it "stops the service via launchctl if service found" do
            provider.should_receive(:shell_out!).
                     with("launchctl unload '/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist'",
                          :group => 1001, :user => 101).
                     and_return(0)

            provider.stop_service
          end
        end

        describe "#restart_service" do
          before do
            Chef::Resource::Service.stub!(:new).and_return(current_resource)

            provider.load_current_resource
            current_resource.stub!(:running).and_return(true)
            provider.stub!(:sleep)
          end

          it "issues a command if given" do
            new_resource.stub!(:restart_command).and_return("reload that thing")

            provider.should_receive(:shell_out!).with("reload that thing")
            provider.restart_service
          end

          it "stops and then starts service" do
            provider.should_receive(:stop_service)
            provider.should_receive(:start_service);

            provider.restart_service
          end
        end
      end
    end
  end
end
