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
require "chef/data_collector/messages/helpers"

class TestMessage
  extend Chef::DataCollector::Messages::Helpers
end

describe Chef::DataCollector::Messages::Helpers do
  describe "#organization" do
    context "when the run is a solo run" do
      it "returns the data collector organization" do
        allow(TestMessage).to receive(:solo_run?).and_return(true)
        expect(TestMessage).to receive(:data_collector_organization).and_return("org1")
        expect(TestMessage.organization).to eq("org1")
      end
    end

    context "when the run is not a solo run" do
      it "returns the data collector organization" do
        allow(TestMessage).to receive(:solo_run?).and_return(false)
        expect(TestMessage).to receive(:chef_server_organization).and_return("org2")
        expect(TestMessage.organization).to eq("org2")
      end
    end
  end

  describe "#data_collector_organization" do
    context "when the org is specified in the config" do
      it "returns the org from the config" do
        Chef::Config[:data_collector][:organization] = "org1"
        expect(TestMessage.data_collector_organization).to eq("org1")
      end
    end

    context "when the org is not specified in the config" do
      it "returns the default chef_solo org" do
        expect(TestMessage.data_collector_organization).to eq("chef_solo")
      end
    end
  end

  describe "#chef_server_organization" do
    context "when the URL is properly formatted" do
      it "returns the org from the parsed URL" do
        Chef::Config[:chef_server_url] = "http://mycompany.com/organizations/myorg"
        expect(TestMessage.chef_server_organization).to eq("myorg")
      end
    end

    context "when the URL is not properly formatted" do
      it "returns unknown_organization" do
        Chef::Config[:chef_server_url] = "http://mycompany.com/what/url/is/this"
        expect(TestMessage.chef_server_organization).to eq("unknown_organization")
      end
    end

    context "when the organization in the URL contains hyphens" do
      it "returns the full org name" do
        Chef::Config[:chef_server_url] = "http://mycompany.com/organizations/myorg-test"
        expect(TestMessage.chef_server_organization).to eq("myorg-test")
      end
    end
  end

  describe "#collector_source" do
    context "when the run is a solo run" do
      it "returns chef_solo" do
        allow(TestMessage).to receive(:solo_run?).and_return(true)
        expect(TestMessage.collector_source).to eq("chef_solo")
      end
    end

    context "when the run is not a solo run" do
      it "returns chef_client" do
        allow(TestMessage).to receive(:solo_run?).and_return(false)
        expect(TestMessage.collector_source).to eq("chef_client")
      end
    end
  end

  describe "#solo_run?" do
    context "when :solo is set in Chef::Config" do
      it "returns true" do
        Chef::Config[:solo] = true
        Chef::Config[:local_mode] = nil
        expect(TestMessage.solo_run?).to be_truthy
      end
    end

    context "when :local_mode is set in Chef::Config" do
      it "returns true" do
        Chef::Config[:solo] = nil
        Chef::Config[:local_mode] = true
        expect(TestMessage.solo_run?).to be_truthy
      end
    end

    context "when neither :solo or :local_mode is set in Chef::Config" do
      it "returns false" do
        Chef::Config[:solo] = nil
        Chef::Config[:local_mode] = nil
        expect(TestMessage.solo_run?).to be_falsey
      end
    end
  end

  describe "#node_uuid" do
    context "when the node UUID can be read" do
      it "returns the read-in node UUID" do
        allow(TestMessage).to receive(:read_node_uuid).and_return("read_uuid")
        expect(TestMessage.node_uuid).to eq("read_uuid")
      end
    end

    context "when the node UUID cannot be read" do
      it "generated a new node UUID" do
        allow(TestMessage).to receive(:read_node_uuid).and_return(nil)
        allow(TestMessage).to receive(:generate_node_uuid).and_return("generated_uuid")
        expect(TestMessage.node_uuid).to eq("generated_uuid")
      end
    end
  end

  describe "#generate_node_uuid" do
    it "generates a new UUID, stores it, and returns it" do
      expect(SecureRandom).to receive(:uuid).and_return("generated_uuid")
      expect(TestMessage).to receive(:update_metadata).with("node_uuid", "generated_uuid")
      expect(TestMessage.generate_node_uuid).to eq("generated_uuid")
    end
  end

  describe "#read_node_uuid" do
    it "reads the node UUID from metadata" do
      expect(TestMessage).to receive(:metadata).and_return({ "node_uuid" => "read_uuid" })
      expect(TestMessage.read_node_uuid).to eq("read_uuid")
    end
  end

  describe "metadata" do
    let(:metadata_filename) { "fake_metadata_file.json" }

    before do
      allow(TestMessage).to receive(:metadata_filename).and_return(metadata_filename)
    end

    context "when the metadata file exists" do
      it "returns the contents of the metadata file" do
        expect(Chef::FileCache).to receive(:load).with(metadata_filename).and_return('{"foo":"bar"}')
        expect(TestMessage.metadata["foo"]).to eq("bar")
      end
    end

    context "when the metadata file does not exist" do
      it "returns an empty hash" do
        expect(Chef::FileCache).to receive(:load).with(metadata_filename).and_raise(Chef::Exceptions::FileNotFound)
        expect(TestMessage.metadata).to eq({})
      end
    end
  end

  describe "#update_metadata" do
    it "updates the file" do
      allow(TestMessage).to receive(:metadata_filename).and_return("fake_metadata_file.json")
      allow(TestMessage).to receive(:metadata).and_return({ "key" => "current_value" })
      expect(Chef::FileCache).to receive(:store).with(
        "fake_metadata_file.json",
        '{"key":"updated_value"}',
        0644
      )

      TestMessage.update_metadata("key", "updated_value")
    end
  end
end
