require "spec_helper"

class RestResourceByQuery < Chef::Resource::RestResource
  property :address, String, required: true
  property :prefix, Integer, required: true
  property :gateway, String

  rest_api_collection "/api/v1/addresses"
  rest_api_document   "/api/v1/address/?ip={address}"
end

class RestResourceByPath < RestResourceByQuery
  rest_api_document   "/api/v1/address/{address}"
end

describe "rest_resource using query-based addressing" do
  before(:each) do
    @cookbook_collection = Chef::CookbookCollection.new([])
    @node = Chef::Node.new
    @node.name "node1"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @resource = RestResourceByQuery.new("set_address", @run_context)
    @resource.address = "192.0.2.1"
    @resource.prefix = 24

    @provider = Chef::Provider::RestResource.new(@resource, @run_context)
    @provider.current_resource = @resource
  end

  it "should include :configure action" do
    expect(@provider).to respond_to(:action_configure)
  end

  it "should include :delete action" do
    expect(@provider).to respond_to(:action_delete)
  end

  it "should include :nothing action" do
    expect(@provider).to respond_to(:action_nothing)
  end

  describe "#rest_postprocess" do
    before do
      @provider.singleton_class.send(:public, :rest_postprocess)
    end
    it "should have a default rest_postprocess implementation" do
      expect(@provider).to respond_to(:rest_postprocess)
    end

    it "should have a non-mutating rest_postprocess implementation" do
      response = "{ data: nil }"

      expect(@provider.rest_postprocess(response.dup)).to eq(response)
    end
  end

  describe "#rest_errorhandler" do
    before do
      @provider.singleton_class.send(:public, :rest_errorhandler)
    end

    it "should have a default rest_errorhandler implementation" do
      expect(@provider).to respond_to(:rest_errorhandler)
    end

    it "should have a non-mutating rest_errorhandler implementation" do
      error_obj = StandardError.new

      expect(@provider.rest_errorhandler(error_obj.dup)).to eq(error_obj)
    end
  end

  describe "#required_properties" do
    before do
      @provider.singleton_class.send(:public, :required_properties)
    end

    it "should include required properties only" do
      expect(@provider.required_properties).to contain_exactly(:address, :prefix)
    end
  end

  describe "#property_map" do
    before do
      @provider.singleton_class.send(:public, :property_map)
    end

    it "should map resource properties to values properly" do
      expect(@provider.property_map).to eq({
                                             address: "192.0.2.1",
                                             prefix: 24,
                                             gateway: nil,
                                             name: "set_address",
                                           })
    end
  end

  describe "#rest_url_collection" do
    before do
      @provider.singleton_class.send(:public, :rest_url_collection)
    end

    it "should return collection URLs properly" do
      expect(@provider.rest_url_collection).to eq("/api/v1/addresses")
    end
  end

  describe "#rest_url_document" do
    before do
      @provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should apply URI templates to document URLs using query syntax properly" do
      expect(@provider.rest_url_document).to eq("/api/v1/address/?ip=192.0.2.1")
    end
  end

  # TODO: Test with path-style URLs
  describe "#rest_identity_implicit" do
    before do
      @provider.singleton_class.send(:public, :rest_identity_implicit)
    end

    it "should return implicit identity properties properly" do
      expect(@provider.rest_identity_implicit).to eq({ "ip" => :address })
    end
  end

  describe "#rest_identity_values" do
    before do
      @provider.singleton_class.send(:public, :rest_identity_values)
    end

    it "should return implicit identity properties and values properly" do
      expect(@provider.rest_identity_values).to eq({ "ip" => "192.0.2.1" })
    end
  end

  # TODO: changed_value
  # TODO: load_current_value
end

describe "rest_resource using path-based addressing" do
  before(:each) do
    @cookbook_collection = Chef::CookbookCollection.new([])
    @node = Chef::Node.new
    @node.name "node1"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)

    @resource = RestResourceByPath.new("set_address", @run_context)
    @resource.address = "192.0.2.1"
    @resource.prefix = 24

    @provider = Chef::Provider::RestResource.new(@resource, @run_context)
    @provider.current_resource = @resource
  end

  describe "#rest_url_document" do
    before do
      @provider.singleton_class.send(:public, :rest_url_document)
    end

    it "should apply URI templates to document URLs using path syntax properly" do
      expect(@provider.rest_url_document).to eq("/api/v1/address/192.0.2.1")
    end
  end

  describe "#rest_identity_implicit" do
    before do
      @provider.singleton_class.send(:public, :rest_identity_implicit)
    end

    it "should return implicit identity properties properly" do
      expect(@provider.rest_identity_implicit).to eq({ "address" => :address })
    end
  end

  describe "#rest_identity_values" do
    before do
      @provider.singleton_class.send(:public, :rest_identity_values)
    end

    it "should return implicit identity properties and values properly" do
      expect(@provider.rest_identity_values).to eq({ "address" => "192.0.2.1" })
    end
  end
end
