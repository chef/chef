#
# Author:: Tyler Ball (<tball@chef.io>)
# Author:: Claire McQuin (<claire@chef.io>)
#
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
require "chef/audit/audit_event_proxy"

describe Chef::Audit::AuditEventProxy do

  let(:stdout) { StringIO.new }
  let(:events) { double("Chef::Events") }
  let(:audit_event_proxy) { Chef::Audit::AuditEventProxy.new(stdout) }

  before do
    Chef::Audit::AuditEventProxy.events = events
  end

  describe "#example_group_started" do

    let(:description) { "poots" }
    let(:group) do
      double("ExampleGroup", :parent_groups => parents,
                             :description => description) end
    let(:notification) { double("Notification", :group => group) }

    context "when notified from a top-level example group" do

      let(:parents) { [double("ExampleGroup")] }

      it "notifies control_group_started event" do
        expect(Chef::Log).to receive(:debug).
          with("Entered \`control_group\` block named poots")
        expect(events).to receive(:control_group_started).
          with(description)
        audit_event_proxy.example_group_started(notification)
      end
    end

    context "when notified from an inner-level example group" do

      let(:parents) { [double("ExampleGroup"), double("OuterExampleGroup")] }

      it "does nothing" do
        expect(events).to_not receive(:control_group_started)
        audit_event_proxy.example_group_started(notification)
      end
    end
  end

  describe "#stop" do

    let(:examples) { [] }
    let(:notification) { double("Notification", :examples => examples) }
    let(:exception) { nil }
    let(:example) { double("Example", :exception => exception) }
    let(:control_group_name) { "audit test" }
    let(:control_data) { double("ControlData") }

    before do
      allow(Chef::Log).to receive(:info) # silence messages to output stream
    end

    it "sends a message that audits completed" do
      expect(Chef::Log).to receive(:info).with("Successfully executed all \`control_group\` blocks and contained examples")
      audit_event_proxy.stop(notification)
    end

    context "when an example succeeded" do

      let(:examples) { [example] }
      let(:excpetion) { nil }

      before do
        allow(audit_event_proxy).to receive(:build_control_from).
          with(example).
          and_return([control_group_name, control_data])
      end

      it "notifies events" do
        expect(events).to receive(:control_example_success).
          with(control_group_name, control_data)
        audit_event_proxy.stop(notification)
      end
    end

    context "when an example failed" do

      let(:examples) { [example] }
      let(:exception) { double("ExpectationNotMet") }

      before do
        allow(audit_event_proxy).to receive(:build_control_from).
          with(example).
          and_return([control_group_name, control_data])
      end

      it "notifies events" do
        expect(events).to receive(:control_example_failure).
          with(control_group_name, control_data, exception)
        audit_event_proxy.stop(notification)
      end
    end

    describe "#build_control_from" do

      let(:examples) { [example] }

      let(:example) do
        double("Example", :metadata => metadata,
                          :description => example_description,
                          :full_description => full_description, :exception => nil) end

      let(:metadata) do
        {
          :described_class => described_class,
          :example_group => example_group,
          :line_number => line,
        }
      end

      let(:example_group) do
        {
          :description => group_description,
          :parent_example_group => parent_group,
        }
      end

      let(:parent_group) do
        {
          :description => control_group_name,
          :parent_example_group => nil,
        }
      end

      let(:line) { 27 }

      let(:control_data) do
        {
          :name => example_description,
          :desc => full_description,
          :resource_type => resource_type,
          :resource_name => resource_name,
          :context => context,
          :line_number => line,
        }
      end

      shared_examples "built control" do

        before do
          if described_class
            allow(described_class).to receive(:instance_variable_get).
              with(:@name).
              and_return(resource_name)
            allow(described_class.class).to receive(:name).
              and_return(described_class.class)
          end
        end

        it "returns the controls block name and example metadata for reporting" do
          expect(events).to receive(:control_example_success).
            with(control_group_name, control_data)
          audit_event_proxy.stop(notification)
        end
      end

      describe "a top-level example" do
        # controls "port 111" do
        #   it "has nobody listening" do
        #     expect(port("111")).to_not be_listening
        #   end
        # end

        # Description parts
        let(:group_description) { "port 111" }
        let(:example_description) { "has nobody listening" }
        let(:full_description) { group_description + " " + example_description }

        # Metadata fields
        let(:described_class) { nil }

        # Example group (metadata[:example_group]) fields
        let(:parent_group) { nil }

        # Expected returns
        let(:control_group_name) { group_description }

        # Control data fields
        let(:resource_type) { nil }
        let(:resource_name) { nil }
        let(:context) { [] }

        include_examples "built control"
      end

      describe "an example with an implicit subject" do
        # controls "application ports" do
        #   control port(111) do
        #     it { is_expected.to_not be_listening }
        #   end
        # end

        # Description parts
        let(:control_group_name) { "application ports" }
        let(:group_description) { "#{resource_type} #{resource_name}" }
        let(:example_description) { "should not be listening" }
        let(:full_description) do
          [control_group_name, group_description,
          example_description].join(" ") end

        # Metadata fields
        let(:described_class) do
          double("Serverspec::Type::Port",
          :class => "Serverspec::Type::Port", :name => resource_name) end

        # Control data fields
        let(:resource_type) { "Port" }
        let(:resource_name) { "111" }
        let(:context) { [] }

        include_examples "built control"
      end

      describe "an example in a nested context" do
        # controls "application ports" do
        #   control "port 111" do
        #     it "is not listening" do
        #       expect(port(111)).to_not be_listening
        #     end
        #   end
        # end

        # Description parts
        let(:control_group_name) { "application ports" }
        let(:group_description) { "port 111" }
        let(:example_description) { "is not listening" }
        let(:full_description) do
          [control_group_name, group_description,
          example_description].join(" ") end

        # Metadata fields
        let(:described_class) { nil }

        # Control data fields
        let(:resource_type) { nil }
        let(:resource_name) { nil }
        let(:context) { [group_description] }

        include_examples "built control"
      end

      describe "an example in a nested context including Serverspec" do
        # controls "application directory" do
        #   control file("/tmp/audit") do
        #     describe file("/tmp/audit/test_file") do
        #       it "is a file" do
        #         expect(subject).to be_file
        #       end
        #     end
        #   end
        # end

        # Description parts
        let(:control_group_name) { "application directory" }
        let(:outer_group_description) { "File \"tmp/audit\"" }
        let(:group_description) { "#{resource_type} #{resource_name}" }
        let(:example_description) { "is a file" }
        let(:full_description) do
          [control_group_name, outer_group_description,
          group_description, example_description].join(" ") end

        # Metadata parts
        let(:described_class) do
          double("Serverspec::Type::File",
          :class => "Serverspec::Type::File", :name => resource_name) end

        # Example group parts
        let(:parent_group) do
          {
            :description => outer_group_description,
            :parent_example_group => control_group,
          }
        end

        let(:control_group) do
          {
            :description => control_group_name,
            :parent_example_group => nil,
          }
        end

        # Control data parts
        let(:resource_type) { "File" }
        let(:resource_name) { "/tmp/audit/test_file" }
        let(:context) { [outer_group_description] }

        include_examples "built control"
      end
    end
  end

end
