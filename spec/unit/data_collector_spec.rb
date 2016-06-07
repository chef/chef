#
# Author:: Adam Leff (<adamleff@chef.io)
# Author:: Ryan Cragun (<ryan@chef.io>)
#
# Copyright:: Copyright 2012-2016, Chef Software Inc.
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
require "chef/data_collector"

describe Chef::DataCollector do
  describe ".register_reporter?" do
    context "when no data collector URL is configured" do
      it "returns false" do
        Chef::Config[:data_collector][:server_url] = nil
        expect(Chef::DataCollector.register_reporter?).to be_falsey
      end
    end

    context "when a data collector URL is configured" do
      before do
        Chef::Config[:data_collector][:server_url] = "http://data_collector"
      end

      context "when operating in why_run mode" do
        it "returns false" do
          Chef::Config[:why_run] = true
          expect(Chef::DataCollector.register_reporter?).to be_falsey
        end
      end

      context "when not operating in why_run mode" do
        before do
          Chef::Config[:why_run] = false
        end

        context "when report is enabled for current mode" do
          it "returns true" do
            allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(true)
            expect(Chef::DataCollector.register_reporter?).to be_truthy
          end
        end

        context "when report is disabled for current mode" do
          it "returns false" do
            allow(Chef::DataCollector).to receive(:reporter_enabled_for_current_mode?).and_return(false)
            expect(Chef::DataCollector.register_reporter?).to be_falsey
          end
        end
      end
    end
  end

  describe ".reporter_enabled_for_current_mode?" do
    context "when running in solo mode" do
      before do
        Chef::Config[:solo] = true
        Chef::Config[:local_mode] = false
      end

      context "when data_collector_mode is :solo" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end

    context "when running in local mode" do
      before do
        Chef::Config[:solo] = false
        Chef::Config[:local_mode] = true
      end

      context "when data_collector_mode is :solo" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end

    context "when running in client mode" do
      before do
        Chef::Config[:solo] = false
        Chef::Config[:local_mode] = false
      end

      context "when data_collector_mode is :solo" do
        it "returns false" do
          Chef::Config[:data_collector][:mode] = :solo
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(false)
        end
      end

      context "when data_collector_mode is :client" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :client
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end

      context "when data_collector_mode is :both" do
        it "returns true" do
          Chef::Config[:data_collector][:mode] = :both
          expect(Chef::DataCollector.reporter_enabled_for_current_mode?).to eq(true)
        end
      end
    end
  end
end

describe Chef::DataCollector::Reporter do
  let(:reporter) { described_class.new }
  let(:run_status) { Chef::RunStatus.new(Chef::Node.new, Chef::EventDispatch::Dispatcher.new) }

  describe '#run_started' do
    before do
      allow(reporter).to receive(:update_run_status)
      allow(reporter).to receive(:send_to_data_collector)
      allow(Chef::DataCollector::Messages).to receive(:run_start_message)
    end

    it "updates the run status" do
      expect(reporter).to receive(:update_run_status).with(run_status)
      reporter.run_started(run_status)
    end

    it "sends the RunStart message output to the Data Collector server" do
      expect(Chef::DataCollector::Messages)
        .to receive(:run_start_message)
        .with(run_status)
        .and_return(key: "value")
      expect(reporter).to receive(:send_to_data_collector).with('{"key":"value"}')
      reporter.run_started(run_status)
    end
  end

  describe '#run_completed' do
    it "sends the run completion" do
      node = Chef::Node.new

      expect(reporter).to receive(:send_run_completion).with(status: "success")
      reporter.run_completed(node)
    end
  end

  describe '#run_failed' do
    it "updates the exception and sends the run completion" do
      expect(reporter).to receive(:send_run_completion).with(status: "failure")
      reporter.run_failed("test_exception")
    end
  end

  describe '#resource_current_state_loaded' do
    let(:new_resource)     { double("new_resource") }
    let(:action)           { double("action") }
    let(:current_resource) { double("current_resource") }

    context "when resource is a nested resource" do
      it "does not update the resource report" do
        allow(reporter).to receive(:nested_resource?).and_return(true)
        expect(reporter).not_to receive(:update_current_resource_report)
        reporter.resource_current_state_loaded(new_resource, action, current_resource)
      end
    end

    context "when resource is not a nested resource" do
      it "updates the resource report" do
        allow(reporter).to receive(:nested_resource?).and_return(false)
        expect(Chef::DataCollector::ResourceReport).to receive(:new).with(
          new_resource,
          action,
          current_resource)
        .and_return("resource_report")
        expect(reporter).to receive(:update_current_resource_report).with("resource_report")
        reporter.resource_current_state_loaded(new_resource, action, current_resource)
      end
    end
  end

  describe '#resource_up_to_date' do
    let(:new_resource)    { double("new_resource") }
    let(:action)          { double("action") }
    let(:resource_report) { double("resource_report") }

    before do
      allow(reporter).to receive(:nested_resource?)
      allow(reporter).to receive(:current_resource_report).and_return(resource_report)
      allow(resource_report).to receive(:up_to_date)
    end

    context "when the resource is a nested resource" do
      it "does not mark the resource report as up-to-date" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(true)
        expect(resource_report).not_to receive(:up_to_date)
        reporter.resource_up_to_date(new_resource, action)
      end
    end

    context "when the resource is not a nested resource" do
      it "marks the resource report as up-to-date" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(false)
        expect(resource_report).to receive(:up_to_date)
        reporter.resource_up_to_date(new_resource, action)
      end
    end
  end

  describe '#resource_skipped' do
    let(:new_resource)    { double("new_resource") }
    let(:action)          { double("action") }
    let(:conditional)     { double("conditional") }
    let(:resource_report) { double("resource_report") }

    before do
      allow(reporter).to receive(:nested_resource?)
      allow(reporter).to receive(:current_resource_report).and_return(resource_report)
      allow(resource_report).to receive(:skipped)
    end

    context "when the resource is a nested resource" do
      it "does not mark the resource report as skipped" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(true)
        expect(resource_report).not_to receive(:skipped).with(conditional)
        reporter.resource_skipped(new_resource, action, conditional)
      end
    end

    context "when the resource is not a nested resource" do
      it "updates the resource report" do
        allow(reporter).to receive(:nested_resource?).and_return(false)
        expect(Chef::DataCollector::ResourceReport).to receive(:new).with(
          new_resource,
          action)
        .and_return("resource_report")
        expect(reporter).to receive(:update_current_resource_report).with("resource_report")
        reporter.resource_skipped(new_resource, action, conditional)
      end

      it "marks the resource report as skipped" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(false)
        expect(resource_report).to receive(:skipped).with(conditional)
        reporter.resource_skipped(new_resource, action, conditional)
      end
    end
  end

  describe '#resource_updated' do
    let(:resource_report) { double("resource_report") }

    before do
      allow(reporter).to receive(:current_resource_report).and_return(resource_report)
      allow(resource_report).to receive(:updated)
    end

    it "marks the resource report as updated" do
      expect(resource_report).to receive(:updated)
      reporter.resource_updated("new_resource", "action")
    end
  end

  describe '#resource_failed' do
    let(:new_resource)    { double("new_resource") }
    let(:action)          { double("action") }
    let(:exception)       { double("exception") }
    let(:error_mapper)    { double("error_mapper") }
    let(:resource_report) { double("resource_report") }

    before do
      allow(reporter).to receive(:update_error_description)
      allow(reporter).to receive(:current_resource_report).and_return(resource_report)
      allow(resource_report).to receive(:failed)
      allow(Chef::Formatters::ErrorMapper).to receive(:resource_failed).and_return(error_mapper)
      allow(error_mapper).to receive(:for_json)
    end

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:resource_failed).with(
        new_resource,
        action,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.resource_failed(new_resource, action, exception)
    end

    context "when the resource is not a nested resource" do
      it "marks the resource report as failed" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(false)
        expect(resource_report).to receive(:failed).with(exception)
        reporter.resource_failed(new_resource, action, exception)
      end
    end

    context "when the resource is a nested resource" do
      it "does not mark the resource report as failed" do
        allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(true)
        expect(resource_report).not_to receive(:failed).with(exception)
        reporter.resource_failed(new_resource, action, exception)
      end
    end
  end

  describe '#resource_completed' do
    let(:new_resource)    { double("new_resource") }
    let(:resource_report) { double("resource_report") }

    before do
      allow(reporter).to receive(:add_completed_resource)
      allow(reporter).to receive(:update_current_resource_report)
      allow(resource_report).to receive(:finish)
    end

    context "when there is no current resource report" do
      it "does not add the updated resource" do
        allow(reporter).to receive(:current_resource_report).and_return(nil)
        expect(reporter).not_to receive(:add_completed_resource)
        reporter.resource_completed(new_resource)
      end
    end

    context "when there is a current resource report" do
      before do
        allow(reporter).to receive(:current_resource_report).and_return(resource_report)
      end

      context "when the resource is a nested resource" do
        it "does not add the updated resource" do
          allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(true)
          expect(reporter).not_to receive(:add_completed_resource)
          reporter.resource_completed(new_resource)
        end
      end

      context "when the resource is not a nested resource" do
        before do
          allow(reporter).to receive(:nested_resource?).with(new_resource).and_return(false)
        end

        it "marks the current resource report as finished" do
          expect(resource_report).to receive(:finish)
          reporter.resource_completed(new_resource)
        end

        it "adds the resource to the updated resource list" do
          expect(reporter).to receive(:add_completed_resource).with(resource_report)
          reporter.resource_completed(new_resource)
        end

        it "nils out the current resource report" do
          expect(reporter).to receive(:update_current_resource_report).with(nil)
          reporter.resource_completed(new_resource)
        end
      end
    end
  end

  describe '#run_list_expanded' do
    it "sets the expanded run list" do
      reporter.run_list_expanded("test_run_list")
      expect(reporter.expanded_run_list).to eq("test_run_list")
    end
  end

  describe '#run_list_expand_failed' do
    let(:node)         { double("node") }
    let(:error_mapper) { double("error_mapper") }
    let(:exception)    { double("exception") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:run_list_expand_failed).with(
        node,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.run_list_expand_failed(node, exception)
    end
  end

  describe '#cookbook_resolution_failed' do
    let(:error_mapper)      { double("error_mapper") }
    let(:exception)         { double("exception") }
    let(:expanded_run_list) { double("expanded_run_list") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:cookbook_resolution_failed).with(
        expanded_run_list,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.cookbook_resolution_failed(expanded_run_list, exception)
    end

  end

  describe '#cookbook_sync_failed' do
    let(:cookbooks)    { double("cookbooks") }
    let(:error_mapper) { double("error_mapper") }
    let(:exception)    { double("exception") }

    it "updates the error description" do
      expect(Chef::Formatters::ErrorMapper).to receive(:cookbook_sync_failed).with(
        cookbooks,
        exception
      ).and_return(error_mapper)
      expect(error_mapper).to receive(:for_json).and_return("error_description")
      expect(reporter).to receive(:update_error_description).with("error_description")
      reporter.cookbook_sync_failed(cookbooks, exception)
    end
  end

  describe '#disable_reporter_on_error' do
    context "when no exception is raise by the block" do
      it "does not disable the reporter" do
        expect(reporter).not_to receive(:disable_data_collector_reporter)
        reporter.send(:disable_reporter_on_error) { true }
      end

      it "does not raise an exception" do
        expect { reporter.send(:disable_reporter_on_error) { true } }.not_to raise_error
      end
    end

    context "when an unexpected exception is raised by the block" do
      it "re-raises the exception" do
        expect { reporter.send(:disable_reporter_on_error) { raise RuntimeError, "bummer" } }.to raise_error(RuntimeError)
      end
    end

    [ Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
      Errno::ECONNREFUSED, EOFError, Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError, Net::ProtocolError, OpenSSL::SSL::SSLError ].each do |exception_class|
      context "when the block raises a #{exception_class} exception" do
        it "disables the reporter" do
          expect(reporter).to receive(:disable_data_collector_reporter)
          reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") }
        end

        context "when raise-on-failure is enabled" do
          it "logs an error and raises" do
            Chef::Config[:data_collector][:raise_on_failure] = true
            expect(Chef::Log).to receive(:error)
            expect { reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") } }.to raise_error(exception_class)
          end
        end

        context "when raise-on-failure is disabled" do
          it "logs a warning and does not raise an exception" do
            Chef::Config[:data_collector][:raise_on_failure] = false
            expect(Chef::Log).to receive(:warn)
            expect { reporter.send(:disable_reporter_on_error) { raise exception_class.new("bummer") } }.not_to raise_error
          end
        end
      end
    end
  end
end
