#
# Author:: Mike Dodge (<mikedodge04@gmail.com>)
# Copyright:: Copyright (c) 2015 Facebook, Inc.
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

describe Chef::Provider::Launchd do

  context "When launchd manages call.mom.weekly" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:provider) { Chef::Provider::Launchd.new(new_resource, run_context) }

    let(:label) { "call.mom.weekly" }
    let(:new_resource) { Chef::Resource::Launchd.new(label) }
    let!(:current_resource) { Chef::Resource::Launchd.new(label) }
    let(:test_plist) { String.new <<-XML }
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>Label</key>
\t<string>call.mom.weekly</string>
\t<key>Program</key>
\t<string>/Library/scripts/call_mom.sh</string>
\t<key>StartCalendarInterval</key>
\t<dict>
\t\t<key>Hour</key>
\t\t<integer>10</integer>
\t\t<key>Weekday</key>
\t\t<integer>7</integer>
\t</dict>
\t<key>TimeOut</key>
\t<integer>300</integer>
</dict>
</plist>
XML
    let(:test_plist_multiple_intervals) { String.new <<-XML }
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>Label</key>
\t<string>call.mom.weekly</string>
\t<key>Program</key>
\t<string>/Library/scripts/call_mom.sh</string>
\t<key>StartCalendarInterval</key>
\t<array>
\t\t<dict>
\t\t\t<key>Hour</key>
\t\t\t<integer>11</integer>
\t\t\t<key>Weekday</key>
\t\t\t<integer>1</integer>
\t\t</dict>
\t\t<dict>
\t\t\t<key>Hour</key>
\t\t\t<integer>12</integer>
\t\t\t<key>Weekday</key>
\t\t\t<integer>2</integer>
\t\t</dict>
\t</array>
\t<key>TimeOut</key>
\t<integer>300</integer>
</dict>
</plist>
XML

    let(:test_hash) do
      {
      "Label" => "call.mom.weekly",
      "Program" => "/Library/scripts/call_mom.sh",
      "StartCalendarInterval" => {
        "Hour" => 10,
        "Weekday" => 7,
      },
      "TimeOut" => 300,
    } end

    before(:each) do
      provider.load_current_resource
    end

    it "resource name and label should be call.mom.weekly" do
      expect(new_resource.name).to eql(label)
      expect(new_resource.label).to eql(label)
    end

    def run_resource_setup_for_action(action)
      new_resource.action(action)
      provider.action = action
      provider.load_current_resource
      provider.define_resource_requirements
      provider.process_resource_requirements
    end

    describe "with type is set to" do
      describe "agent" do
        it "path should be /Library/LaunchAgents/call.mom.weekly.plist" do
          new_resource.type "agent"
          expect(provider.gen_path_from_type).
            to eq("/Library/LaunchAgents/call.mom.weekly.plist")
        end
      end
      describe "daemon" do
        it "path should be /Library/LaunchDaemons/call.mom.weekly.plist" do
          expect(provider.gen_path_from_type).
            to eq("/Library/LaunchDaemons/call.mom.weekly.plist")
        end
      end
    end

    describe "with a :create action and" do
      describe "program is passed" do
        it "should produce the test_plist from properties" do
          new_resource.program "/Library/scripts/call_mom.sh"
          new_resource.time_out 300
          new_resource.start_calendar_interval "Hour" => 10, "Weekday" => 7
          expect(provider.content?).to be_truthy
          expect(provider.content).to eql(test_plist)
        end
      end

      describe "start_calendar_interval is passed" do
        it "should allow array of Hashes" do
          allowed = (1..2).collect do |num|
            {
              "Hour"    => 10 + num,
              "Weekday" => num,
            }
          end
          new_resource.program "/Library/scripts/call_mom.sh"
          new_resource.time_out 300
          new_resource.start_calendar_interval allowed
          expect(provider.content?).to be_truthy
          expect(provider.content).to eql(test_plist_multiple_intervals)
        end

        it "should allow all StartCalendarInterval keys" do
          allowed = {
            "Minute"  => 1,
            "Hour"    => 1,
            "Day"     => 1,
            "Weekday" => 1,
            "Month"   => 1,
          }
          new_resource.program "/Library/scripts/call_mom.sh"
          new_resource.time_out 300
          new_resource.start_calendar_interval allowed
          expect(provider.content?).to be_truthy
          %w{Minute Hour Day Weekday Month}.each do |key|
            expect(provider.content).to include("<key>#{key}</key>")
          end
        end

        it "should not allow invalid ShowCalendarInterval keys" do
          new_resource.program "/Library/scripts/call_mom.sh"
          new_resource.time_out 300
          expect do
            new_resource.start_calendar_interval "Hourly" => 1
          end.to raise_error(/Hourly are invalid/)
        end

        it "should not allow non-integer values" do
          new_resource.program "/Library/scripts/call_mom.sh"
          new_resource.time_out 300
          expect do
            new_resource.start_calendar_interval "Weekday" => "1-2"
          end.to raise_error(/Invalid value.*\(1-2\)/)
        end
      end

      describe "hash is passed" do
        it "should produce the test_plist content from the plist_hash property" do
          new_resource.plist_hash test_hash
          expect(provider.content?).to be_truthy
          expect(provider.content).to eql(test_plist)
        end
      end
    end

    describe "with an :enable action" do
      describe "and the file has been updated" do
        before(:each) do
          allow(provider).to receive(
            :manage_plist).with(:create).and_return(true)
          allow(provider).to receive(
            :manage_service).with(:restart).and_return(true)
        end

        it "should call manage_service with a :restart action" do
          expect(provider.manage_service(:restart)).to be_truthy
        end

        it "works with action enable" do
          expect(run_resource_setup_for_action(:enable)).to be_truthy
          provider.action_enable
        end
      end

      describe "and the file has not been updated" do
        before(:each) do
          allow(provider).to receive(
            :manage_plist).with(:create).and_return(nil)
          allow(provider).to receive(
            :manage_service).with(:enable).and_return(true)
        end

        it "should call manage_service with a :enable action" do
          expect(provider.manage_service(:enable)).to be_truthy
        end

        it "works with action enable" do
          expect(run_resource_setup_for_action(:enable)).to be_truthy
          provider.action_enable
        end
      end
    end

    describe "with an :delete action" do
      describe "and the ld file is present" do
        before(:each) do
          allow(File).to receive(:exists?).and_return(true)
          allow(provider).to receive(
            :manage_service).with(:disable).and_return(true)
          allow(provider).to receive(
            :manage_plist).with(:delete).and_return(true)
        end

        it "should call manage_service with a :disable action" do
          expect(provider.manage_service(:disable)).to be_truthy
        end

        it "works with action :delete" do
          expect(run_resource_setup_for_action(:delete)).to be_truthy
          provider.action_delete
        end
      end

      describe "and the ld file is not present" do
        before(:each) do
          allow(File).to receive(:exists?).and_return(false)
          allow(provider).to receive(
            :manage_plist).with(:delete).and_return(true)
        end

        it "works with action :delete" do
          expect(run_resource_setup_for_action(:delete)).to be_truthy
          provider.action_delete
        end
      end
    end
  end
end
