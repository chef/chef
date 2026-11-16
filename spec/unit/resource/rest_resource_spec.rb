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

API_HOST = "https://api.example.com".freeze
API_BASE_URL = "#{API_HOST}/api/v1/".freeze
CORE_REST_RESOURCE = "core::rest_resource".freeze
COLLECTION_PATH = "/api/v1/addresses".freeze
QUERY_DOCUMENT_PATH = "/api/v1/address/?ip={address}".freeze
PATH_DOCUMENT_PATH = "/api/v1/address/{address}".freeze
CONTENT_TYPE_JSON = "application/json".freeze
RESOURCE_NAME = "set_address".freeze
ADDRESS = "192.0.2.1".freeze
OTHER_ADDRESS = "172.16.32.85".freeze
EMPTY_JSON_ARRAY = "[]".freeze
AUTO_DOCUMENT_PATH = "/api/v1/addresses/{address}".freeze

HEADER_ACCEPT = "Accept".freeze
HEADER_CONTENT_TYPE = "Content-Type".freeze
JSON_REQUEST_HEADERS = { HEADER_ACCEPT => CONTENT_TYPE_JSON, HEADER_CONTENT_TYPE => CONTENT_TYPE_JSON }.freeze
JSON_RESPONSE_HEADERS = { HEADER_CONTENT_TYPE => CONTENT_TYPE_JSON }.freeze

PATCH_PREFIX_WRONG_BODY = "{\"address\":\"#{ADDRESS}\",\"prefix\":25}".freeze
POST_CREATE_BODY = "{\"address\":\"#{ADDRESS}\",\"prefix\":24,\"ip\":\"#{ADDRESS}\"}".freeze

COLLECTION_URL = "#{API_BASE_URL}addresses".freeze
QUERY_RESOURCE_URL = "#{API_BASE_URL}address/?ip=#{ADDRESS}".freeze
PATH_RESOURCE_URL = "#{API_BASE_URL}address/#{ADDRESS}".freeze
IDENTITY_RESOURCE_URL = "#{API_BASE_URL}addresses/#{ADDRESS}".freeze

QUERY_RESOURCE_PATH = "/api/v1/address/?ip=#{ADDRESS}".freeze
PATH_RESOURCE_PATH = "/api/v1/address/#{ADDRESS}".freeze
IDENTITY_RESOURCE_PATH = "/api/v1/addresses/#{ADDRESS}".freeze

class RestResourceByQuery < Chef::Resource
  use CORE_REST_RESOURCE

  provides :rest_resource_by_query, target_mode: true

  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_collection COLLECTION_PATH
  rest_api_document   QUERY_DOCUMENT_PATH
  rest_property_map({
    address: "address",
    prefix: "prefix",
    gateway: "gateway",
  })
end

class RestResourceByPath < RestResourceByQuery
  provides :rest_resource_by_path, target_mode: true

  rest_api_document PATH_DOCUMENT_PATH
end

class RestResourceWithEndpoint < Chef::Resource
  use CORE_REST_RESOURCE

  provides :rest_resource_with_endpoint, target_mode: true

  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_endpoint API_HOST
  rest_api_collection COLLECTION_PATH
  rest_api_document   PATH_DOCUMENT_PATH
  rest_property_map({
    address: "address",
    prefix: "prefix",
    gateway: "gateway",
  })
end

class RestResourceWithIdentityProperty < Chef::Resource
  use CORE_REST_RESOURCE

  provides :rest_resource_with_identity_property, target_mode: true

  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_collection COLLECTION_PATH
  rest_identity_property :address
  rest_property_map({
    address: "address",
    prefix: "prefix",
    gateway: "gateway",
  })
end

class RestResourceWithEndpointAndIdentityProperty < Chef::Resource
  use CORE_REST_RESOURCE

  provides :rest_resource_with_endpoint_and_identity_property, target_mode: true

  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_endpoint API_HOST
  rest_api_collection COLLECTION_PATH
  rest_identity_property :address
  rest_property_map({
    address: "address",
    prefix: "prefix",
    gateway: "gateway",
  })
end

describe "rest_resource using query-based addressing" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   API_BASE_URL,
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
    RestResourceByQuery.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
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
        address: ADDRESS,
        prefix: 24,
        gateway: nil,
        name: RESOURCE_NAME,
      })
    end
  end

  describe "#rest_url_collection" do
    before do
      provider.singleton_class.send(:public, :rest_url_collection)
    end

    it "should return collection URLs properly" do
      expect(provider.rest_url_collection).to eq(COLLECTION_PATH)
    end
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should apply URI templates to document URLs using query syntax properly" do
      expect(provider.rest_url_document).to eq(QUERY_RESOURCE_PATH)
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
      expect(provider.rest_identity_values).to eq({ "ip" => ADDRESS })
    end
  end

  # TODO: changed_value
  # TODO: load_current_value

  # this might be a functional test, but it runs on any O/S so I leave it here
  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:addresses_other) { JSON.generate([{ "address": OTHER_ADDRESS }]) }
    let(:address_exists) { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }
    let(:prefix_wrong) { JSON.generate({ "address": ADDRESS, "prefix": 25, "gateway": ADDRESS }) }

    it "should be idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should PATCH if a property is incorrect" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: prefix_wrong, headers: JSON_RESPONSE_HEADERS)
      stub_request(:patch, QUERY_RESOURCE_URL)
        .with(
          body: PATCH_PREFIX_WRONG_BODY,
          headers: JSON_REQUEST_HEADERS
        )
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should POST if there's no resources at all" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: EMPTY_JSON_ARRAY, headers: JSON_RESPONSE_HEADERS)
      stub_request(:post, COLLECTION_URL)
        .with(
          body: POST_CREATE_BODY
        )
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should POST if the specific resource does not exist" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_other, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 404, body: "", headers: {})
      stub_request(:post, COLLECTION_URL)
        .with(
          body: POST_CREATE_BODY
        )
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should be idempotent if the resouces needs deleting and there are no resources at all" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: EMPTY_JSON_ARRAY, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should be idempotent if the resource doesn't exist" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_other, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 404, body: "", headers: {})
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be false
    end

    it "should DELETE the resource if it exists and matches" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:delete, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: "", headers: {})
      resource.run_action(:delete)
      expect(resource.updated_by_last_action?).to be true
    end

    it "should DELETE the resource if it exists and doesn't match" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: prefix_wrong, headers: JSON_RESPONSE_HEADERS)
      stub_request(:delete, QUERY_RESOURCE_URL)
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
      endpoint:   API_BASE_URL,
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
    RestResourceByPath.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
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
      expect(provider.rest_url_document).to eq(PATH_RESOURCE_PATH)
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
      expect(provider.rest_identity_values).to eq({ "address" => ADDRESS })
    end
  end

end

describe "rest_resource using rest_api_endpoint" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   RestResourceWithEndpoint.rest_api_endpoint,
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
    RestResourceWithEndpoint.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
      resource.prefix = 24
      resource.action :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) do
    allow(Chef::Provider).to receive(:new).and_return(provider)
  end

  it "should store rest_api_endpoint on the resource class" do
    expect(resource.class.rest_api_endpoint).to eq(API_HOST)
  end

  describe "#rest_url_collection" do
    before do
      provider.singleton_class.send(:public, :rest_url_collection)
    end

    it "should prepend the endpoint to the collection URL" do
      expect(provider.rest_url_collection).to eq(COLLECTION_URL)
    end
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should prepend the endpoint to the document URL" do
      expect(provider.rest_url_document).to eq(PATH_RESOURCE_URL)
    end
  end

  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:address_exists) { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }

    it "should be idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, PATH_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end
  end
end

describe "rest_resource using rest_identity_property" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   API_BASE_URL,
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
    RestResourceWithIdentityProperty.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
      resource.prefix = 24
      resource.action :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) do
    allow(Chef::Provider).to receive(:new).and_return(provider)
  end

  it "should store rest_identity_property on the resource class" do
    expect(resource.class.rest_identity_property).to eq(:address)
  end

  it "should auto-generate rest_api_document from collection and identity property" do
    expect(resource.class.rest_api_document).to eq(AUTO_DOCUMENT_PATH)
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should expand the auto-generated document URL using the identity property value" do
      expect(provider.rest_url_document).to eq(IDENTITY_RESOURCE_PATH)
    end
  end

  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:address_exists) { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }

    it "should be idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, IDENTITY_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end
  end
end

describe "rest_resource using rest_api_endpoint and rest_identity_property" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   RestResourceWithEndpointAndIdentityProperty.rest_api_endpoint,
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
    RestResourceWithEndpointAndIdentityProperty.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
      resource.prefix = 24
      resource.action :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) do
    allow(Chef::Provider).to receive(:new).and_return(provider)
  end

  describe "#rest_url_collection" do
    before do
      provider.singleton_class.send(:public, :rest_url_collection)
    end

    it "should prepend the endpoint to the collection URL" do
      expect(provider.rest_url_collection).to eq(COLLECTION_URL)
    end
  end

  describe "#rest_url_document" do
    before do
      provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should build the full document URL from endpoint, collection, and identity property" do
      expect(provider.rest_url_document).to eq(IDENTITY_RESOURCE_URL)
    end
  end

  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:address_exists) { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }

    it "should be idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, IDENTITY_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end
  end
end

# These two blocks demonstrate that configuring the endpoint via Train directly
# (rather than via rest_api_endpoint) still works. The resource uses relative
# paths only; the base URL is owned entirely by the Train connection's endpoint option.

describe "rest_resource with endpoint configured via Train transport (query-based)" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   API_HOST,
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
    RestResourceByQuery.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
      resource.prefix  = 24
      resource.action  :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) { allow(Chef::Provider).to receive(:new).and_return(provider) }

  it "should have no rest_api_endpoint set on the resource class" do
    expect(resource.class.rest_api_endpoint).to be_nil
  end

  describe "#rest_url_collection" do
    before { provider.singleton_class.send(:public, :rest_url_collection) }

    it "returns a relative collection URL (endpoint lives in Train)" do
      expect(provider.rest_url_collection).to eq(COLLECTION_PATH)
    end
  end

  describe "#rest_url_document" do
    before { provider.singleton_class.send(:public, :rest_url_document) }

    it "returns a relative document URL (endpoint lives in Train)" do
      expect(provider.rest_url_document).to eq(QUERY_RESOURCE_PATH)
    end
  end

  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:address_exists)   { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }

    it "resolves the full URL via the Train transport endpoint and is idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, QUERY_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end
  end
end

describe "rest_resource with endpoint configured via Train transport (path-based)" do
  let(:train) {
    Train.create(
      "rest", {
      endpoint:   API_HOST,
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
    RestResourceByPath.new(RESOURCE_NAME, run_context).tap do |resource|
      resource.address = ADDRESS
      resource.prefix  = 24
      resource.action  :configure
    end
  end

  let(:provider) do
    resource.provider_for_action(:configure).tap do |provider|
      provider.current_resource = resource
      allow(provider).to receive(:api_connection).and_return(train)
    end
  end

  before(:each) { allow(Chef::Provider).to receive(:new).and_return(provider) }

  it "should have no rest_api_endpoint set on the resource class" do
    expect(resource.class.rest_api_endpoint).to be_nil
  end

  describe "#rest_url_document" do
    before { provider.singleton_class.send(:public, :rest_url_document) }

    it "returns a relative document URL (endpoint lives in Train)" do
      expect(provider.rest_url_document).to eq(PATH_RESOURCE_PATH)
    end
  end

  describe "when managing a resource" do
    before { WebMock.disable_net_connect! }
    let(:addresses_exists) { JSON.generate([{ "address": ADDRESS }]) }
    let(:address_exists)   { JSON.generate({ "address": ADDRESS, "prefix": 24, "gateway": ADDRESS }) }

    it "resolves the full URL via the Train transport endpoint and is idempotent" do
      stub_request(:get, COLLECTION_URL)
        .to_return(status: 200, body: addresses_exists, headers: JSON_RESPONSE_HEADERS)
      stub_request(:get, PATH_RESOURCE_URL)
        .to_return(status: 200, body: address_exists, headers: JSON_RESPONSE_HEADERS)
      resource.run_action(:configure)
      expect(resource.updated_by_last_action?).to be false
    end
  end
end
