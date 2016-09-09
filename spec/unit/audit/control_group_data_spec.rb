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
require "securerandom"

describe Chef::Audit::AuditData do

  let(:node_name) { "noodles" }
  let(:run_id) { SecureRandom.uuid }
  let(:audit_data) { described_class.new(node_name, run_id) }

  let(:control_group_1) { double("control group 1") }
  let(:control_group_2) { double("control group 2") }

  describe "#add_control_group" do
    context "when no control groups have been added" do
      it "stores the control group" do
        audit_data.add_control_group(control_group_1)
        expect(audit_data.control_groups).to include(control_group_1)
      end

    end

    context "when adding additional control groups" do

      before do
        audit_data.add_control_group(control_group_1)
      end

      it "stores the control group" do
        audit_data.add_control_group(control_group_2)
        expect(audit_data.control_groups).to include(control_group_2)
      end

      it "stores all control groups" do
        audit_data.add_control_group(control_group_2)
        expect(audit_data.control_groups).to include(control_group_1)
      end
    end
  end

  describe "#to_hash" do

    let(:audit_data_hash) { audit_data.to_hash }

    it "returns a hash" do
      expect(audit_data_hash).to be_a(Hash)
    end

    it "describes a Chef::Audit::AuditData object" do
      keys = [:node_name, :run_id, :start_time, :end_time, :control_groups]
      expect(audit_data_hash.keys).to match_array(keys)
    end

    describe ":control_groups" do

      let(:control_hash_1) { { :name => "control group 1" } }
      let(:control_hash_2) { { :name => "control group 2" } }

      let(:control_groups) { audit_data_hash[:control_groups] }

      context "with no control groups added" do
        it "is an empty list" do
          expect(control_groups).to eq []
        end
      end

      context "with one control group added" do

        before do
          allow(audit_data).to receive(:control_groups).and_return([control_group_1])
        end

        it "is a one-element list containing the control group hash" do
          expect(control_group_1).to receive(:to_hash).once.and_return(control_hash_1)
          expect(control_groups.size).to eq 1
          expect(control_groups).to include(control_hash_1)
        end
      end

      context "with multiple control groups added" do

        before do
          allow(audit_data).to receive(:control_groups).and_return([control_group_1, control_group_2])
        end

        it "is a list of control group hashes" do
          expect(control_group_1).to receive(:to_hash).and_return(control_hash_1)
          expect(control_group_2).to receive(:to_hash).and_return(control_hash_2)
          expect(control_groups.size).to eq 2
          expect(control_groups).to include(control_hash_1)
          expect(control_groups).to include(control_hash_2)
        end
      end
    end
  end
end

describe Chef::Audit::ControlData do

  let(:name) { "ramen" }
  let(:resource_type) { double("Service") }
  let(:resource_name) { "mysql" }
  let(:context) { nil }
  let(:line_number) { 27 }

  let(:control_data) do
    described_class.new(name: name,
                        resource_type: resource_type, resource_name: resource_name,
                        context: context, line_number: line_number) end

  describe "#to_hash" do

    let(:control_data_hash) { control_data.to_hash }

    it "returns a hash" do
      expect(control_data_hash).to be_a(Hash)
    end

    it "describes a Chef::Audit::ControlData object" do
      keys = [:name, :resource_type, :resource_name, :context, :status, :details]
      expect(control_data_hash.keys).to match_array(keys)
    end

    context "when context is nil" do

      it "sets :context to an empty array" do
        expect(control_data_hash[:context]).to eq []
      end

    end

    context "when context is non-nil" do

      let(:context) { ["outer"] }

      it "sets :context to its value" do
        expect(control_data_hash[:context]).to eq context
      end
    end
  end
end

describe Chef::Audit::ControlGroupData do

  let(:name) { "balloon" }
  let(:control_group_data) { described_class.new(name) }

  shared_context "control data" do

    let(:name) { "" }
    let(:resource_type) { nil }
    let(:resource_name) { nil }
    let(:context) { nil }
    let(:line_number) { 0 }

    let(:control_data) do
      {
        :name => name,
        :resource_type => resource_type,
        :resource_name => resource_name,
        :context => context,
        :line_number => line_number,
      }
    end

  end

  shared_context "control" do
    include_context "control data"

    let(:control) do
      Chef::Audit::ControlData.new(name: name,
                                   resource_type: resource_type, resource_name: resource_name,
                                   context: context, line_number: line_number) end

    before do
      allow(Chef::Audit::ControlData).to receive(:new).
        with(name: name, resource_type: resource_type,
             resource_name: resource_name, context: context,
             line_number: line_number).
        and_return(control)
    end
  end

  describe "#new" do
    it "has status \"success\"" do
      expect(control_group_data.status).to eq "success"
    end
  end

  describe "#example_success" do
    include_context "control"

    def notify_success
      control_group_data.example_success(control_data)
    end

    it "increments the number of successful audits" do
      num_success = control_group_data.number_succeeded
      notify_success
      expect(control_group_data.number_succeeded).to eq (num_success + 1)
    end

    it "does not increment the number of failed audits" do
      num_failed = control_group_data.number_failed
      notify_success
      expect(control_group_data.number_failed).to eq (num_failed)
    end

    it "marks the audit's status as success" do
      notify_success
      expect(control.status).to eq "success"
    end

    it "does not modify its own status" do
      expect(control_group_data).to_not receive(:status=)
      status = control_group_data.status
      notify_success
      expect(control_group_data.status).to eq status
    end

    it "saves the control" do
      controls = control_group_data.controls
      expect(controls).to_not include(control)
      notify_success
      expect(controls).to include(control)
    end
  end

  describe "#example_failure" do
    include_context "control"

    let(:details) { "poop" }

    def notify_failure
      control_group_data.example_failure(control_data, details)
    end

    it "does not increment the number of successful audits" do
      num_success = control_group_data.number_succeeded
      notify_failure
      expect(control_group_data.number_succeeded).to eq num_success
    end

    it "increments the number of failed audits" do
      num_failed = control_group_data.number_failed
      notify_failure
      expect(control_group_data.number_failed).to eq (num_failed + 1)
    end

    it "marks the audit's status as failure" do
      notify_failure
      expect(control.status).to eq "failure"
    end

    it "marks its own status as failure" do
      notify_failure
      expect(control_group_data.status).to eq "failure"
    end

    it "saves the control" do
      controls = control_group_data.controls
      expect(controls).to_not include(control)
      notify_failure
      expect(controls).to include(control)
    end

    context "when details are not provided" do

      let(:details) { nil }

      it "does not save details to the control" do
        default_details = control.details
        expect(control).to_not receive(:details=)
        notify_failure
        expect(control.details).to eq default_details
      end
    end

    context "when details are provided" do

      let(:details) { "yep that didn't work" }

      it "saves details to the control" do
        notify_failure
        expect(control.details).to eq details
      end
    end
  end

  shared_examples "multiple audits" do |success_or_failure|
    include_context "control"

    let(:num_success) { 0 }
    let(:num_failure) { 0 }

    before do
      if num_failure == 0
        num_success.times { control_group_data.example_success(control_data) }
      elsif num_success == 0
        num_failure.times { control_group_data.example_failure(control_data, nil) }
      end
    end

    it "counts the number of successful audits" do
      expect(control_group_data.number_succeeded).to eq num_success
    end

    it "counts the number of failed audits" do
      expect(control_group_data.number_failed).to eq num_failure
    end

    it "marks its status as \"#{success_or_failure}\"" do
      expect(control_group_data.status).to eq success_or_failure
    end
  end

  context "when all audits pass" do
    include_examples "multiple audits", "success" do
      let(:num_success) { 3 }
    end
  end

  context "when one audit fails" do
    shared_examples "mixed audit results" do
      include_examples "multiple audits", "failure" do

        let(:audit_results) { [] }
        let(:num_success) { audit_results.count("success") }
        let(:num_failure) { 1 }

        before do
          audit_results.each do |result|
            if result == "success"
              control_group_data.example_success(control_data)
            else
              control_group_data.example_failure(control_data, nil)
            end
          end
        end
      end
    end

    context "and it's the first audit" do
      include_examples "mixed audit results" do
        let(:audit_results) { %w{failure success success} }
      end
    end

    context "and it's an audit in the middle" do
      include_examples "mixed audit results" do
        let(:audit_results) { %w{success failure success} }
      end
    end

    context "and it's the last audit" do
      include_examples "mixed audit results" do
        let(:audit_results) { %w{success success failure} }
      end
    end
  end

  context "when all audits fail" do
    include_examples "multiple audits", "failure" do
      let(:num_failure) { 3 }
    end
  end

  describe "#to_hash" do

    let(:control_group_data_hash) { control_group_data.to_hash }

    it "returns a hash" do
      expect(control_group_data_hash).to be_a(Hash)
    end

    it "describes a Chef::Audit::ControlGroupData object" do
      keys = [:name, :status, :number_succeeded, :number_failed,
        :controls, :id]
      expect(control_group_data_hash.keys).to match_array(keys)
    end

    describe ":controls" do

      let(:control_group_controls) { control_group_data_hash[:controls] }

      context "with no controls added" do
        it "is an empty list" do
          expect(control_group_controls).to eq []
        end
      end

      context "with one control added" do
        include_context "control"

        let(:control_list) { [control_data] }
        let(:control_hash) { control.to_hash }

        before do
          expect(control_group_data).to receive(:controls).twice.and_return(control_list)
          expect(control_data).to receive(:to_hash).and_return(control_hash)
        end

        it "is a one-element list containing the control hash" do
          expect(control_group_controls.size).to eq 1
          expect(control_group_controls).to include(control_hash)
        end

        it "adds a sequence number to the control" do
          control_group_data.to_hash
          expect(control_hash).to have_key(:sequence_number)
        end

      end

      context "with multiple controls added" do

        let(:control_hash_1) { { :line_number => 27 } }
        let(:control_hash_2) { { :line_number => 13 } }
        let(:control_hash_3) { { :line_number => 35 } }

        let(:control_1) do
          double("control 1",
          :line_number => control_hash_1[:line_number],
          :to_hash => control_hash_1) end
        let(:control_2) do
          double("control 2",
          :line_number => control_hash_2[:line_number],
          :to_hash => control_hash_2) end
        let(:control_3) do
          double("control 3",
          :line_number => control_hash_3[:line_number],
          :to_hash => control_hash_3) end

        let(:control_list) { [control_1, control_2, control_3] }
        let(:ordered_control_hashes) { [control_hash_2, control_hash_1, control_hash_3] }

        before do
          # Another way to do this would be to call #example_success
          # or #example_failure per control hash, but we'd have to
          # then stub #create_control and it's a lot of extra stubbing work.
          # We can't stub the controls reader to return a list of
          # controls because of the call to sort! and the following
          # reading of controls.
          control_group_data.instance_variable_set(:@controls, control_list)
        end

        it "is a list of control group hashes ordered by line number" do
          expect(control_group_controls.size).to eq 3
          expect(control_group_controls).to eq ordered_control_hashes
        end

        it "assigns sequence numbers in order" do
          control_group_data.to_hash
          ordered_control_hashes.each_with_index do |control_hash, idx|
            expect(control_hash[:sequence_number]).to eq idx + 1
          end
        end
      end
    end
  end

end
