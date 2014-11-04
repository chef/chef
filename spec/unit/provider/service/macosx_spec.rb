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
        allow(ENV).to receive(:[]).with('HOME').and_return("/User/someuser")
      end

      it "includes users's LaunchAgents folder" do
        expect(described_class.gather_plist_dirs).to include("#{ENV['HOME']}/Library/LaunchAgents")
      end
    end

    context "when HOME directory is not set" do
      before do
        allow(ENV).to receive(:[]).with('HOME').and_return(nil)
      end

      it "doesn't include user's LaunchAgents folder" do
        expect(described_class.gather_plist_dirs).not_to include("~/Library/LaunchAgents")
      end
    end
  end

  context "when service name is given as" do
    let(:node) { Chef::Node.new }
    let(:events) {Chef::EventDispatch::Dispatcher.new}
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:provider) { described_class.new(new_resource, run_context) }
    let(:launchctl_stdout) { StringIO.new }
    let(:plutil_stdout) { String.new <<-XML }
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>io.redis.redis-server</string>
</dict>
</plist>
XML

    ["redis-server", "io.redis.redis-server"].each do |service_name|
      before do
        allow(Dir).to receive(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
        allow(provider).to receive(:shell_out!).
                 with("launchctl list", {:group => 1001, :user => 101}).
                 and_return(double("Status", :stdout => launchctl_stdout))
        allow(provider).to receive(:shell_out).
                 with(/launchctl list /,
                      {:group => nil, :user => nil}).
                 and_return(double("Status",
                                 :stdout => launchctl_stdout, :exitstatus => 0))
        allow(provider).to receive(:shell_out!).
                 with(/plutil -convert xml1 -o/).
                 and_return(double("Status", :stdout => plutil_stdout))

        allow(File).to receive(:stat).and_return(double("stat", :gid => 1001, :uid => 101))
      end

      context "#{service_name}" do
        let(:new_resource) { Chef::Resource::Service.new(service_name) }
        let!(:current_resource) { Chef::Resource::Service.new(service_name) }

        describe "#load_current_resource" do

          # CHEF-5223 "you can't glob for a file that hasn't been converged
          # onto the node yet."
          context "when the plist doesn't exist" do

            def run_resource_setup_for_action(action)
              new_resource.action(action)
              provider.action = action
              provider.load_current_resource
              provider.define_resource_requirements
              provider.process_resource_requirements
            end

            before do
              allow(Dir).to receive(:glob).and_return([])
              allow(provider).to receive(:shell_out!).
                       with(/plutil -convert xml1 -o/).
                       and_raise(Mixlib::ShellOut::ShellCommandFailed)
            end

            it "works for action :nothing" do
              expect { run_resource_setup_for_action(:nothing) }.not_to raise_error
            end

            it "works for action :start" do
              expect { run_resource_setup_for_action(:start) }.not_to raise_error
            end

            it "errors if action is :enable" do
              expect { run_resource_setup_for_action(:enable) }.to raise_error(Chef::Exceptions::Service)
            end

            it "errors if action is :disable" do
              expect { run_resource_setup_for_action(:disable) }.to raise_error(Chef::Exceptions::Service)
            end
          end

          context "when launchctl returns pid in service list" do
            let(:launchctl_stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  7777  - io.redis.redis-server
  - - com.lol.stopped-thing
  SVC_LIST

            before do
              provider.load_current_resource
            end

            it "sets resource running state to true" do
              expect(provider.current_resource.running).to be_true
            end

            it "sets resouce enabled state to true" do
              expect(provider.current_resource.enabled).to be_true
            end
          end

          describe "running unsupported actions" do
            let(:launchctl_stdout) { StringIO.new <<-SVC_LIST }
12761 - 0x100114220.old.machinit.thing
7777  - io.redis.redis-server
- - com.lol.stopped-thing
SVC_LIST

            before do
              allow(Dir).to receive(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
            end
            it "should throw an exception when reload action is attempted" do
              expect {provider.run_action(:reload)}.to raise_error(Chef::Exceptions::UnsupportedAction)
            end
          end
          context "when launchctl returns empty service pid" do
            let(:launchctl_stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  - - io.redis.redis-server
  - - com.lol.stopped-thing
  SVC_LIST

            before do
              provider.load_current_resource
            end

            it "sets resource running state to false" do
              expect(provider.current_resource.running).to be_false
            end

            it "sets resouce enabled state to true" do
              expect(provider.current_resource.enabled).to be_true
            end
          end

          context "when launchctl doesn't return service entry at all" do
            let(:launchctl_stdout) { StringIO.new <<-SVC_LIST }
  12761 - 0x100114220.old.machinit.thing
  - - com.lol.stopped-thing
  SVC_LIST

            it "sets service running state to false" do
              provider.load_current_resource
              expect(provider.current_resource.running).to be_false
            end

            context "and plist for service is not available" do
              before do
                allow(Dir).to receive(:glob).and_return([])
                provider.load_current_resource
              end

              it "sets resouce enabled state to false" do
                expect(provider.current_resource.enabled).to be_false
              end
            end

            context "and plist for service is available" do
              before do
                allow(Dir).to receive(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist"], [])
                provider.load_current_resource
              end

              it "sets resouce enabled state to true" do
                expect(provider.current_resource.enabled).to be_true
              end
            end

            describe "and several plists match service name" do
              it "throws exception" do
                allow(Dir).to receive(:glob).and_return(["/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist",
                                             "/Users/wtf/something.plist"])
                provider.load_current_resource
                provider.define_resource_requirements
                expect { provider.process_resource_requirements }.to raise_error(Chef::Exceptions::Service)
              end
            end
          end
        end
        describe "#start_service" do
          before do
            allow(Chef::Resource::Service).to receive(:new).and_return(current_resource)
            provider.load_current_resource
            allow(current_resource).to receive(:running).and_return(false)
          end

          it "calls the start command if one is specified and service is not running" do
            allow(new_resource).to receive(:start_command).and_return("cowsay dirty")

            expect(provider).to receive(:shell_out_with_systems_locale!).with("cowsay dirty")
            provider.start_service
          end

          it "shows warning message if service is already running" do
            allow(current_resource).to receive(:running).and_return(true)
            expect(Chef::Log).to receive(:debug).with("service[#{service_name}] already running, not starting")

            provider.start_service
          end

          it "starts service via launchctl if service found" do
            expect(provider).to receive(:shell_out_with_systems_locale!).
                     with("launchctl load -w '/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist'",
                           :group => 1001, :user => 101).
                     and_return(0)

            provider.start_service
          end
        end

        describe "#stop_service" do
          before do
            allow(Chef::Resource::Service).to receive(:new).and_return(current_resource)

            provider.load_current_resource
            allow(current_resource).to receive(:running).and_return(true)
          end

          it "calls the stop command if one is specified and service is running" do
            allow(new_resource).to receive(:stop_command).and_return("kill -9 123")

            expect(provider).to receive(:shell_out_with_systems_locale!).with("kill -9 123")
            provider.stop_service
          end

          it "shows warning message if service is not running" do
            allow(current_resource).to receive(:running).and_return(false)
            expect(Chef::Log).to receive(:debug).with("service[#{service_name}] not running, not stopping")

            provider.stop_service
          end

          it "stops the service via launchctl if service found" do
            expect(provider).to receive(:shell_out_with_systems_locale!).
                     with("launchctl unload '/Users/igor/Library/LaunchAgents/io.redis.redis-server.plist'",
                          :group => 1001, :user => 101).
                     and_return(0)

            provider.stop_service
          end
        end

        describe "#restart_service" do
          before do
            allow(Chef::Resource::Service).to receive(:new).and_return(current_resource)

            provider.load_current_resource
            allow(current_resource).to receive(:running).and_return(true)
            allow(provider).to receive(:sleep)
          end

          it "issues a command if given" do
            allow(new_resource).to receive(:restart_command).and_return("reload that thing")

            expect(provider).to receive(:shell_out_with_systems_locale!).with("reload that thing")
            provider.restart_service
          end

          it "stops and then starts service" do
            expect(provider).to receive(:stop_service)
            expect(provider).to receive(:start_service);

            provider.restart_service
          end
        end
      end
    end
  end
end
