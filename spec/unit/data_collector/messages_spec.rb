#
# Author:: Adam Leff (<adamleff@chef.io)
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
require "ffi_yajl"
require "chef/data_collector/messages/helpers"

describe Chef::DataCollector::Messages do
  describe "#run_start_message" do
    let(:run_status) { Chef::RunStatus.new(Chef::Node.new, Chef::EventDispatch::Dispatcher.new) }
    let(:required_fields) do
      %w{
        chef_server_fqdn
        entity_uuid
        id
        message_version
        message_type
        node_name
        organization_name
        run_id
        source
        start_time
      }
    end
    let(:optional_fields) { [] }

    before do
      allow(run_status).to receive(:start_time).and_return(Time.now)
    end

    it "is not missing any required fields" do
      missing_fields = required_fields.select do |key|
        !Chef::DataCollector::Messages.run_start_message(run_status).key?(key)
      end

      expect(missing_fields).to eq([])
    end

    it "does not have any extra fields" do
      extra_fields = Chef::DataCollector::Messages.run_start_message(run_status).keys.select do |key|
        !required_fields.include?(key) && !optional_fields.include?(key)
      end

      expect(extra_fields).to eq([])
    end
  end

  describe "#run_end_message" do
    let(:node)       { Chef::Node.new }
    let(:run_status) { Chef::RunStatus.new(node, Chef::EventDispatch::Dispatcher.new) }
    let(:report1)  { double("report1", report_data: { "status" => "updated" }) }
    let(:report2)  { double("report2", report_data: { "status" => "skipped" }) }
    let(:reporter_data) do
      {
        run_status: run_status,
        resources: [report1, report2],
      }
    end

    before do
      allow(run_status).to receive(:start_time).and_return(Time.now)
      allow(run_status).to receive(:end_time).and_return(Time.now)
    end

    it "includes a valid node object in the payload" do
      message = Chef::DataCollector::Messages.run_end_message(reporter_data)
      expect(message["node"]).to be_an_instance_of(Chef::Node)
    end

    it "returns a sane JSON representation of the node object" do
      node.chef_environment = "my_test_environment"
      node.run_list.add("recipe[my_test_cookbook::default]")
      message = FFI_Yajl::Parser.parse(Chef::DataCollector::Messages.run_end_message(reporter_data).to_json)

      expect(message["node"]["chef_environment"]).to eq("my_test_environment")
      expect(message["node"]["run_list"]).to eq(["recipe[my_test_cookbook::default]"])
    end

    context "when the run was successful" do
      let(:required_fields) do
        %w{
          chef_server_fqdn
          entity_uuid
          id
          end_time
          expanded_run_list
          message_type
          message_version
          node
          node_name
          organization_name
          resources
          run_id
          run_list
          source
          start_time
          status
          total_resource_count
          updated_resource_count
          deprecations
        }
      end
      let(:optional_fields) { %w{error policy_group policy_name} }

      before do
        allow(run_status).to receive(:exception).and_return(nil)
      end

      it "is not missing any required fields" do
        missing_fields = required_fields.select do |key|
          !Chef::DataCollector::Messages.run_end_message(reporter_data).key?(key)
        end
        expect(missing_fields).to eq([])
      end

      it "does not have any extra fields" do
        extra_fields = Chef::DataCollector::Messages.run_end_message(reporter_data).keys.select do |key|
          !required_fields.include?(key) && !optional_fields.include?(key)
        end
        expect(extra_fields).to eq([])
      end

      it "only includes updated resources in its count" do
        message = Chef::DataCollector::Messages.run_end_message(reporter_data)
        expect(message["total_resource_count"]).to eq(2)
        expect(message["updated_resource_count"]).to eq(1)
      end
    end

    context "when the run was not successful" do
      let(:required_fields) do
        %w{
          chef_server_fqdn
          entity_uuid
          id
          end_time
          error
          expanded_run_list
          message_type
          message_version
          node
          node_name
          organization_name
          resources
          run_id
          run_list
          source
          start_time
          status
          total_resource_count
          updated_resource_count
          deprecations
        }
      end
      let(:optional_fields) { %w{policy_group policy_name} }

      before do
        allow(run_status).to receive(:exception).and_return(RuntimeError.new("an error happened"))
      end

      it "is not missing any required fields" do
        missing_fields = required_fields.select do |key|
          !Chef::DataCollector::Messages.run_end_message(reporter_data).key?(key)
        end
        expect(missing_fields).to eq([])
      end

      it "does not have any extra fields" do
        extra_fields = Chef::DataCollector::Messages.run_end_message(reporter_data).keys.select do |key|
          !required_fields.include?(key) && !optional_fields.include?(key)
        end
        expect(extra_fields).to eq([])
      end
    end
  end

  describe "#run_end_message in policy mode" do
    let(:node) { Chef::Node.new }
    let(:run_status) { Chef::RunStatus.new(node, Chef::EventDispatch::Dispatcher.new) }
    let(:report1)  { double("report1", report_data: { "status" => "updated" }) }
    let(:report2)  { double("report2", report_data: { "status" => "skipped" }) }
    let(:reporter_data) do
      {
        run_status: run_status,
        resources: [report1, report2],
      }
    end

    before do
      allow(run_status).to receive(:start_time).and_return(Time.now)
      allow(run_status).to receive(:end_time).and_return(Time.now)
      node.policy_group = "test"
      node.policy_name = "policy-test"
    end

    it "includes a valid node object in the payload" do
      message = Chef::DataCollector::Messages.run_end_message(reporter_data)
      expect(message["node"]).to be_an_instance_of(Chef::Node)
    end

    it "returns a sane JSON representation of the node object" do
      node.chef_environment = "my_test_environment"
      node.run_list.add("recipe[my_test_cookbook::default]")
      message = FFI_Yajl::Parser.parse(Chef::DataCollector::Messages.run_end_message(reporter_data).to_json)

      expect(message["node"]["chef_environment"]).to eq("my_test_environment")
      expect(message["node"]["run_list"]).to eq(["recipe[my_test_cookbook::default]"])
      expect(message["node"]["policy_name"]).to eq("policy-test")
      expect(message["node"]["policy_group"]).to eq("test")
    end

    context "when the run was successful" do
      let(:required_fields) do
        %w{
          chef_server_fqdn
          entity_uuid
          id
          end_time
          expanded_run_list
          message_type
          message_version
          node
          node_name
          organization_name
          resources
          run_id
          run_list
          source
          start_time
          status
          total_resource_count
          updated_resource_count
          deprecations
          policy_name
          policy_group
        }
      end
      let(:optional_fields) { %w{error} }

      before do
        allow(run_status).to receive(:exception).and_return(nil)
      end

      it "is not missing any required fields" do
        missing_fields = required_fields.select do |key|
          !Chef::DataCollector::Messages.run_end_message(reporter_data).key?(key)
        end
        expect(missing_fields).to eq([])
      end

      it "does not have any extra fields" do
        extra_fields = Chef::DataCollector::Messages.run_end_message(reporter_data).keys.select do |key|
          !required_fields.include?(key) && !optional_fields.include?(key)
        end
        expect(extra_fields).to eq([])
      end

      it "only includes updated resources in its count" do
        message = Chef::DataCollector::Messages.run_end_message(reporter_data)
        expect(message["total_resource_count"]).to eq(2)
        expect(message["updated_resource_count"]).to eq(1)
      end
    end

    context "when the run was not successful" do
      let(:required_fields) do
        %w{
          chef_server_fqdn
          entity_uuid
          id
          end_time
          error
          expanded_run_list
          message_type
          message_version
          node
          node_name
          organization_name
          resources
          run_id
          run_list
          source
          start_time
          status
          total_resource_count
          updated_resource_count
          deprecations
          policy_name
          policy_group
        }
      end
      let(:optional_fields) { [] }

      before do
        allow(run_status).to receive(:exception).and_return(RuntimeError.new("an error happened"))
      end

      it "is not missing any required fields" do
        missing_fields = required_fields.select do |key|
          !Chef::DataCollector::Messages.run_end_message(reporter_data).key?(key)
        end
        expect(missing_fields).to eq([])
      end

      it "does not have any extra fields" do
        extra_fields = Chef::DataCollector::Messages.run_end_message(reporter_data).keys.select do |key|
          !required_fields.include?(key) && !optional_fields.include?(key)
        end
        expect(extra_fields).to eq([])
      end
    end
  end
end
