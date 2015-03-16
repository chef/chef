#
# Author:: Tyler Ball (<tball@chef.io>)
# Author:: Claire McQuin (<claire@getchef.com>)
#
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::Audit::AuditReporter do

  let(:rest) { double("rest") }
  let(:reporter) { described_class.new(rest) }
  let(:node) { double("node", :name => "sofreshsoclean") }
  let(:run_id) { 0 }
  let(:start_time) { Time.new(2014, 12, 3, 9, 31, 05, "-08:00") }
  let(:end_time) { Time.new(2014, 12, 3, 9, 36, 14, "-08:00") }
  let(:run_status) { instance_double(Chef::RunStatus, :node => node, :run_id => run_id,
    :start_time => start_time, :end_time => end_time) }

  describe "#audit_phase_start" do

    it "notifies audit phase start to debug log" do
      expect(Chef::Log).to receive(:debug).with(/Audit Reporter starting/)
      reporter.audit_phase_start(run_status)
    end

    it "initializes an AuditData object" do
      expect(Chef::Audit::AuditData).to receive(:new).with(run_status.node.name, run_status.run_id)
      reporter.audit_phase_start(run_status)
    end

    it "saves the run status" do
      reporter.audit_phase_start(run_status)
      expect(reporter.instance_variable_get(:@run_status)).to eq run_status
    end
  end

  describe "#run_completed" do

    let(:audit_data) { Chef::Audit::AuditData.new(node.name, run_id) }
    let(:run_data) { audit_data.to_hash }

    before do
      allow(reporter).to receive(:auditing_enabled?).and_return(true)
      allow(reporter).to receive(:run_status).and_return(run_status)
      allow(rest).to receive(:create_url).and_return(true)
      allow(rest).to receive(:post).and_return(true)
      allow(reporter).to receive(:audit_data).and_return(audit_data)
      allow(reporter).to receive(:run_status).and_return(run_status)
      allow(audit_data).to receive(:to_hash).and_return(run_data)
    end

    describe "a successful run with auditing enabled" do
      it "sets run start and end times" do
        iso_start_time = "2014-12-03T17:31:05Z"
        iso_end_time = "2014-12-03T17:36:14Z"

        reporter.run_completed(node)
        expect(audit_data.start_time).to eq iso_start_time
        expect(audit_data.end_time).to eq iso_end_time
      end

      it "posts audit data to server endpoint" do
        endpoint = "api.opscode.us/orgname/controls"
        headers = {
          'X-Ops-Audit-Report-Protocol-Version' => Chef::Audit::AuditReporter::PROTOCOL_VERSION
        }

        expect(rest).to receive(:create_url).
          with("controls").
          and_return(endpoint)
        expect(rest).to receive(:post).
          with(endpoint, run_data, headers)
        reporter.run_completed(node)
      end

      context "when unable to post to server" do

        let(:error) do
          e = StandardError.new
          e.set_backtrace(caller)
          e
        end

        before do
          expect(rest).to receive(:post).and_raise(error)
          allow(error).to receive(:respond_to?).and_call_original
        end

        context "the error is an http error" do

          let(:response) { double("response", :code => code) }

          before do
            expect(Chef::Log).to receive(:debug).with(/Sending audit report/)
            expect(Chef::Log).to receive(:debug).with(/Audit Report/)
            allow(error).to receive(:response).and_return(response)
            expect(error).to receive(:respond_to?).with(:response).and_return(true)
          end

          context "when the code is 404" do

            let(:code) { "404" }

            it "logs that the server doesn't support audit reporting" do
              expect(Chef::Log).to receive(:debug).with(/Server doesn't support audit reporting/)
              reporter.run_completed(node)
            end
          end

          shared_examples "non-404 error code" do

            it "saves the error report" do
              expect(Chef::FileCache).to receive(:store).
                with("failed-audit-data.json", an_instance_of(String), 0640).
                and_return(true)
              expect(Chef::FileCache).to receive(:load).
                with("failed-audit-data.json", false).
                and_return(true)
              expect(Chef::Log).to receive(:error).with(/Failed to post audit report to server/)
              reporter.run_completed(node)
            end

          end

          context "when the code is not 404" do
            include_examples "non-404 error code" do
              let(:code) { "505" }
            end
          end

          context "when there is no code" do
            include_examples "non-404 error code" do
              let(:code) { nil }
            end
          end

        end

        context "the error is not an http error" do

          it "logs the error" do
            expect(error).to receive(:respond_to?).with(:response).and_return(false)
            expect(Chef::Log).to receive(:error).with(/Failed to post audit report to server/)
            reporter.run_completed(node)
          end

        end

        context "when reporting url fatals are enabled" do

          before do
            allow(Chef::Config).to receive(:[]).
              with(:enable_reporting_url_fatals).
              and_return(true)
          end

          it "raises the error" do
            expect(error).to receive(:respond_to?).with(:response).and_return(false)
            allow(Chef::Log).to receive(:error).and_return(true)
            expect(Chef::Log).to receive(:error).with(/Reporting fatals enabled. Aborting run./)
            expect{ reporter.run_completed(node) }.to raise_error(error)
          end

        end
      end
    end

    context "when auditing is not enabled" do

      before do
        allow(Chef::Log).to receive(:debug)
      end

      it "doesn't send reports" do
        expect(reporter).to receive(:auditing_enabled?).and_return(false)
        expect(Chef::Log).to receive(:debug).with("Audit Reports are disabled. Skipping sending reports.")
        reporter.run_completed(node)
      end

    end

    context "when the run fails before audits" do

      before do
        allow(Chef::Log).to receive(:debug)
      end

      it "doesn't send reports" do
        expect(reporter).to receive(:auditing_enabled?).and_return(true)
        expect(reporter).to receive(:run_status).and_return(nil)
        expect(Chef::Log).to receive(:debug).with("Run failed before audit mode was initialized, not sending audit report to server")
        reporter.run_completed(node)
      end

    end
  end

  describe "#run_failed" do

    let(:audit_data) { Chef::Audit::AuditData.new(node.name, run_id) }
    let(:run_data) { audit_data.to_hash }

    let(:error) { double("AuditError", :class => "Chef::Exception::AuditError",
      :message => "Well that certainly didn't work",
      :backtrace => ["line 0", "line 1", "line 2"]) }

    before do
      allow(reporter).to receive(:auditing_enabled?).and_return(true)
      allow(reporter).to receive(:run_status).and_return(run_status)
      allow(reporter).to receive(:audit_data).and_return(audit_data)
      allow(audit_data).to receive(:to_hash).and_return(run_data)
    end

    it "adds the error information to the reported data" do
      expect(rest).to receive(:create_url)
      expect(rest).to receive(:post)
      reporter.run_failed(error)
      expect(run_data).to have_key(:error)
      expect(run_data[:error]).to eq "Chef::Exception::AuditError: Well that certainly didn't work\n" +
        "line 0\nline 1\nline 2"
    end

  end

  shared_context "audit data" do

    let(:control_group_foo) { instance_double(Chef::Audit::ControlGroupData,
      :metadata => double("foo metadata")) }
    let(:control_group_bar) { instance_double(Chef::Audit::ControlGroupData,
      :metadata => double("bar metadata")) }

    let(:ordered_control_groups) {
      {
        "foo" => control_group_foo,
        "bar" => control_group_bar
      }
    }

    let(:audit_data) { instance_double(Chef::Audit::AuditData,
      :add_control_group => true) }

    let(:run_context) { instance_double(Chef::RunContext,
      :audits => ordered_control_groups) }

    before do
      allow(reporter).to receive(:ordered_control_groups).and_return(ordered_control_groups)
      allow(reporter).to receive(:audit_data).and_return(audit_data)
      allow(reporter).to receive(:run_status).and_return(run_status)
      allow(run_status).to receive(:run_context).and_return(run_context)
    end
  end

  describe "#audit_phase_complete" do
    include_context "audit data"

    it "notifies audit phase finished to debug log" do
      expect(Chef::Log).to receive(:debug).with(/Audit Reporter completed/)
      reporter.audit_phase_complete
    end

    it "collects audit data" do
      ordered_control_groups.each do |_name, group|
        expect(audit_data).to receive(:add_control_group).with(group)
      end
      reporter.audit_phase_complete
    end
  end

  describe "#audit_phase_failed" do
    include_context "audit data"

    let(:error) { double("Exception") }

    it "notifies audit phase failed to debug log" do
      expect(Chef::Log).to receive(:debug).with(/Audit Reporter failed/)
      reporter.audit_phase_failed(error)
    end

    it "collects audit data" do
      ordered_control_groups.each do |_name, group|
        expect(audit_data).to receive(:add_control_group).with(group)
      end
      reporter.audit_phase_failed(error)
    end
  end

  describe "#control_group_started" do
    include_context "audit data"

    let(:name) { "bat" }
    let(:control_group) { instance_double(Chef::Audit::ControlGroupData,
      :metadata => double("metadata")) }

    before do
      allow(Chef::Audit::ControlGroupData).to receive(:new).
        with(name, control_group.metadata).
        and_return(control_group)
    end

    it "stores the control group" do
      expect(ordered_control_groups).to receive(:has_key?).with(name).and_return(false)
      allow(run_context.audits).to receive(:[]).with(name).and_return(control_group)
      expect(ordered_control_groups).to receive(:store).
        with(name, control_group).
        and_call_original
      reporter.control_group_started(name)
      # stubbed :has_key? above, which is used by the have_key matcher,
      # so instead we check the response to Hash's #key? because luckily
      # #key? does not call #has_key?
      expect(ordered_control_groups.key?(name)).to be true
      expect(ordered_control_groups[name]).to eq control_group
    end

    context "when a control group with the same name has been seen" do
      it "raises an exception" do
        expect(ordered_control_groups).to receive(:has_key?).with(name).and_return(true)
        expect{ reporter.control_group_started(name) }.to raise_error(Chef::Exceptions::AuditControlGroupDuplicate)
      end
    end
  end

  describe "#control_example_success" do
    include_context "audit data"

    let(:name) { "foo" }
    let(:example_data) { double("example data") }

    it "notifies the control group the example succeeded" do
      expect(control_group_foo).to receive(:example_success).with(example_data)
      reporter.control_example_success(name, example_data)
    end
  end

  describe "#control_example_failure" do
    include_context "audit data"

    let(:name) { "bar" }
    let(:example_data) { double("example data") }
    let(:error) { double("Exception", :message => "oopsie") }

    it "notifies the control group the example failed" do
      expect(control_group_bar).to receive(:example_failure).
        with(example_data, error.message)
      reporter.control_example_failure(name, example_data, error)
    end
  end

  describe "#auditing_enabled?" do
    shared_examples "enabled?" do |true_or_false|

      it "returns #{true_or_false}" do
        expect(Chef::Config).to receive(:[]).
          with(:audit_mode).
          and_return(audit_setting)
        expect(reporter.auditing_enabled?).to be true_or_false
      end
    end

    context "when auditing is disabled" do
      include_examples "enabled?", false do
        let(:audit_setting) { :disabled }
      end
    end

    context "when auditing in audit-only mode" do
      include_examples "enabled?", true do
        let(:audit_setting) { :audit_only }
      end
    end

    context "when auditing is enabled" do
      include_examples "enabled?", true do
        let(:audit_setting) { :enabled }
      end
    end
  end

end
