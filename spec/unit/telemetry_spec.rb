
require_relative "../../lib/chef/telemetry"
require "spec_helper"

class Chef
  class Telemetry::Mock < Telemetry::Base
    attr_reader :run_ending_payload
    def run_ending(opts)
      @run_ending_payload = super(opts)
    end
  end
end

REGEX = {
  version: /^(\d+|\d+\.\d+|\d+\.\d+\.\d+)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/,
  datetime: /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)((-(\d{2}):(\d{2})|Z)?)$/,
}.freeze

describe "Telemetry" do
  before(:each) do
    @cookbook_repo = File.expand_path(File.join(__dir__, "..", "data", "cookbooks"))
    ####### Loading test cookbooks
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @cookbook = @cookbook_collection[:openldap]
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    ####### Resource creation for testing
    new_resource_1 = Chef::Resource::File.new("/tmp/a-file.txt")
    new_resource_1.recipe_name = "Test Recipe 1"
    new_resource_2 = Chef::Resource::File.new("/tmp/b-file.txt")
    new_resource_2.recipe_name = "Test Recipe 2"
    @all_resources = [new_resource_1, new_resource_2]
    ####### Resource addition to run context
    @run_context.resource_collection.all_resources.replace(@all_resources)
  end

  let(:repo_path) { File.expand_path("../..", __dir__) }
  let(:mock_path) { File.join(repo_path, "spec", "data") }
  let(:valid_client_api_data) { File.read("#{mock_path}/valid_client_api_data.json") }
  let(:tm) { Chef::Telemetry::Mock.new }
  let(:chef_license_key) { "free-42727540-ddc8-4d4b-0000-80662e03cd73-0000" }

  before do
    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/listLicenses")
      .to_return(
        body: {
          "data": [chef_license_key],
          "message": "",
          "status_code": 200,
        }.to_json,
        headers: { content_type: "application/json" }
      )

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: chef_license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(
        body: valid_client_api_data ,
        headers: { content_type: "application/json" }
      )

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: [chef_license_key, ENV["CHEF_LICENSE_KEY"]].join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(
        body: valid_client_api_data ,
        headers: { content_type: "application/json" }
      )

    stub_request(:get, "#{ChefLicensing::Config.license_server_url}/v1/client")
      .with(query: { licenseId: [ENV["CHEF_LICENSE_KEY"], chef_license_key].join(","), entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(
        body: valid_client_api_data ,
        headers: { content_type: "application/json" }
      )
  end

  describe "when it runs with a nested profile" do
    it "sets the wrapper fields" do
      ChefLicensing::Context.license = ChefLicensing.client(license_keys: [chef_license_key])
      tm.run_ending(run_context: @run_context)
      expect(tm.run_ending_payload).not_to eq({})
      expect(tm.run_ending_payload.class).to eq(Hash)
      expect(tm.run_ending_payload[:source]).to match(/^chef:\d+\.\d+\.\d+$/)
      expect(tm.run_ending_payload[:licenseIds]).not_to eq([])
      expect(tm.run_ending_payload[:createdTimeUTC]).to match(REGEX[:datetime])
      expect(tm.run_ending_payload[:type]).to match(/^job$/)
    end

    it "sets the job fields" do
      ChefLicensing::Context.license = ChefLicensing.client(license_keys: [chef_license_key])
      tm.run_ending(run_context: @run_context)
      j = tm.run_ending_payload[:jobs][0]
      expect(j).not_to eq({})
      expect(j.class).to eq(Hash)
      expect(j[:type]).to eq("Infra")

      expect(j[:environment][:host]).to match(/^\S+$/)
      expect(j[:environment][:os]).to match(/^\S+$/)
      expect(j[:environment][:version]).to match(REGEX[:version])
      expect(j[:environment][:architecture]).not_to eq("")

      expect(j[:content].class).to eq(Array)
      j[:content].each do |c|
        expect(c[:version]).to match(REGEX[:version])
      end

      expect(j[:steps].class).to eq(Array)
      j[:steps].each do |s|
        expect(s[:name]).to match(/Test Recipe/)
        expect(s[:resources].class).to eq(Array)
        s[:resources].each do |r|
          expect(r[:type]).to eq("chef-resource")
          expect(r[:name]).to eq("file")
        end
      end
    end
  end
end
