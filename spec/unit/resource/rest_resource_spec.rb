#
# Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "train"
require "train-rest"

class RestResourceByQuery < Chef::Resource
  use "core::rest_resource"

  provides :rest_resource_by_query, target_mode: true

  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_collection "/api/v1/addresses"
  rest_api_document   "/api/v1/address/?ip={address}"
  rest_property_map({
    address: "address",
    prefix: "prefix",
    gateway: "gateway",
  })
end

class RestResourceByPath < RestResourceByQuery
  provides :rest_resource_by_path, target_mode: true

  rest_api_document "/api/v1/address/{address}"
end

describe "rest_resource using query-based addressing" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   "https://api.example.com/api/v1/",
      debug_rest: true,
      logger:     Chef::Log,
    }
    ).connection
  }

  let(:run_context) do
    cookbook_collection = Chef::CookbookCollection.new([])
    node = Chef::Node.new
    node.name "node1"
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:resource) do
    RestResourceByQuery.new("set_address", run_context).tap do |resource|
      resource.address = "192.0.2.1"
      resource.prefix = 24
      resource.action :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource # for some stubby tests that don't call LCR
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) do
    allow(Chef::Provider).to receive(:new).and_return(provider)
  end

  it "should include :configure action" do
    expect(provider).to respond_to(:action_configure)
  end

  it "should include :delete action" do
    expect(provider).to respond_to(:action_delete)
  end

  it "should include :nothing action" do
    expect(provider).to respond_to(:action_nothing)
  end

  it "sets the default action as :configure" do
    expect(resource.action).to eql([:configure])
  end

  it "supports :configure action" do
    expect { resource.action :configure }.not_to raise_error
  end

  it "supports :delete action" do
    expect { resource.action :delete }.not_to raise_error
  end

  it "should mixin RestResourceDSL" do
    expect(resource.class.ancestors).to include(Chef::DSL::RestResource)
  end

  describe "#rest_postprocess" do
    before do
      provider.singleton_class.send(:public, :rest_postprocess)
    end
    it "should have a default rest_postprocess implementation" do
      expect(provider).to respond_to(:rest_postprocess)
    end

    it "should have a non-mutating rest_postprocess implementation" do
      response = "{ data: nil }"

      expect(provider.rest_postprocess(response.dup)).to eq(response)
    end
  end

  describe "#rest_errorhandler" do
    before do
      provider.singleton_class.send(:public, :rest_errorhandler)
    end

    it "should have a default rest_errorhandler implementation" do
      expect(provider).to respond_to(:rest_errorhandler)
    end

    it "should have a non-mutating rest_errorhandler implementation" do
      error_obj = StandardError.new

      expect(provider.rest_errorhandler(error_obj.dup)).to eq(error_obj)
    end
  end

  describe "#required_properties" do
    before do
      provider.singleton_class.send(:public, :required_properties)
    end

    it "should include required properties only" do
      expect(provider.required_properties).to contain_exactly(:address, :prefix)
    end
  end

  describe "#property_map" do
    before do
      provider.singleton_class.send(:public, :property_map)
    end

    it "should map resource properties to values properly" do
      expect(provider.property_map).to eq({
        address: "192.0.2.1",
        prefix: 24,
        gateway: nil,
        name: "set_address",
      })
    end
  end

  describe "#rest_url_collection" do
    before do
      provider.singleton_class.send(:public, :rest_url_collection)
    end

    it "should return collection URLs properly" do
      expect(provider.rest_url_collection).to eq("/api/v1/addresses")
    end
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should apply URI templates to document URLs using query syntax properly" do
      expect(provider.rest_url_document).to eq("/api/v1/address/?ip=192.0.2.1")
    end
  end

  # TODO: Test with path-style URLs
  describe "#rest_identity_implicit" do
    before do
      provider.singleton_class.send(:public, :rest_identity_implicit)
    end

    it "should return implicit identity properties properly" do
      expect(provider.rest_identity_implicit).to eq({ "ip" => :address })
    end
  end

  describe "#rest_identity_values" do
    before do
      provider.singleton_class.send(:public, :rest_identity_values)
    end

    it "should return implicit identity properties and values properly" do
      expect(provider.rest_identity_values).to eq({ "ip" => "192.0.2.1" })
    end
  end

  # TODO: changed_value
  # TODO: load_current_value

  # this might be a functional test, but it runs on any O/S so I leave it here
  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": "192.0.2.1" }]) }
    let(:addresses_other) { JSON.generate([{ "address": "172.16.32.85" }]) }
    let(:address_exists) { JSON.generate({ "address": "192.0.2.1", "prefix": 24, "gateway": "192.0.2.1" }) }
    let(:prefix_wrong) { JSON.generate({ "address": "192.0.2.1", "prefix": 25, "gateway": "192.0.2.1" }) }

    it "should be idempotent" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_exists, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: address_exists, headers: { "Content-Type" => "application/json" })
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should PATCH if a property is incorrect" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_exists, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: prefix_wrong, headers: { "Content-Type" => "application/json" })
      stub_request(:patch, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .with(
          body: "{\"address\":\"192.0.2.1\",\"prefix\":25}",
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
          }
        )
        .to_return(status: 200, body: address_exists, headers: { "Content-Type" => "application/json" })
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should POST if there's no resources at all" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
      stub_request(:post, "https://api.example.com/api/v1/addresses")
        .with(
          body: "{\"address\":\"192.0.2.1\",\"prefix\":24,\"ip\":\"192.0.2.1\"}"
        )
        .to_return(status: 200, body: address_exists, headers: { "Content-Type" => "application/json" })
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should POST if the specific resource does not exist" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_other, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 404, body: "", headers: {})
      stub_request(:post, "https://api.example.com/api/v1/addresses")
        .with(
          body: "{\"address\":\"192.0.2.1\",\"prefix\":24,\"ip\":\"192.0.2.1\"}"
        )
        .to_return(status: 200, body: address_exists, headers: { "Content-Type" => "application/json" })
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should be idempotent if the resouces needs deleting and there are no resources at all" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should be idempotent if the resource doesn't exist" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_other, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 404, body: "", headers: {})
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should DELETE the resource if it exists and matches" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_exists, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: address_exists, headers: { "Content-Type" => "application/json" })
      stub_request(:delete, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: "", headers: {})
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should DELETE the resource if it exists and doesn't match" do
      stub_request(:get, "https://api.example.com/api/v1/addresses")
        .to_return(status: 200, body: addresses_exists, headers: { "Content-Type" => "application/json" })
      stub_request(:get, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: prefix_wrong, headers: { "Content-Type" => "application/json" })
      stub_request(:delete, "https://api.example.com/api/v1/address/?ip=192.0.2.1")
        .to_return(status: 200, body: "", headers: {})
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be true
    end
  end
end

describe "rest_resource using path-based addressing" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   "https://api.example.com/api/v1/",
      debug_rest: true,
      logger:     Chef::Log,
    }
    ).connection
  }

  let(:run_context) do
    cookbook_collection = Chef::CookbookCollection.new([])
    node = Chef::Node.new
    node.name "node1"
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:resource) do
    RestResourceByPath.new("set_address", run_context).tap do |resource|
      resource.address = "192.0.2.1"
      resource.prefix = 24
      resource.action :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource # for some stubby tests that don't call LCR
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) do
    allow(Chef::Provider).to receive(:new).and_return(provider)
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should apply URI templates to document URLs using path syntax properly" do
      expect(provider.rest_url_document).to eq("/api/v1/address/192.0.2.1")
    end
  end

  describe "#rest_identity_implicit" do
    before do
      provider.singleton_class.send(:public, :rest_identity_implicit)
    end

    it "should return implicit identity properties properly" do
      expect(provider.rest_identity_implicit).to eq({ "address" => :address })
    end
  end

  describe "#rest_identity_values" do
    before do
      provider.singleton_class.send(:public, :rest_identity_values)
    end

    it "should return implicit identity properties and values properly" do
      expect(provider.rest_identity_values).to eq({ "address" => "192.0.2.1" })
    end
  end

end
