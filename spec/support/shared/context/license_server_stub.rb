# spec/support/license_server_stub.rb
#
# Shared context for stubbing Chef Licensing API calls in tests,
# including license server URL and client data.

RSpec.shared_context "license server stubs" do
  let(:repo_path) { File.expand_path("../../..", __dir__) }
  let(:mock_path) { File.join(repo_path, "data") }
  let(:valid_client_api_data) { File.read("#{mock_path}/valid_client_api_data.json") }
  let(:license_key) { "free-42727540-ddc8-4d4b-0000-80662e03cd73-0000" }

  before do
    # Disable all real HTTP connections
    WebMock.disable_net_connect!

    # Stub license_server_url and license_keys
    allow(ChefLicensing::Config).to receive(:license_server_url).and_return("http://www.samplelicenseserver.com")
    allow(ChefLicensing).to receive(:license_keys).and_return([license_key])
    chef_license_server_url = ChefLicensing::Config.license_server_url.chomp("/")

    # Stub external API requests
    stub_request(:get, "#{chef_license_server_url}/v1/listLicenses")
      .to_return(
        body: {
          "data": [license_key],
          "message": "",
          "status_code": 200,
        }.to_json,
        headers: { content_type: "application/json" }
      )

    stub_request(:get, "#{chef_license_server_url}/v1/client")
      .with(query: { licenseId: license_key, entitlementId: ChefLicensing::Config.chef_entitlement_id })
      .to_return(
        body: valid_client_api_data,
        headers: { content_type: "application/json" }
      )

    # Set up ChefLicensing context
    ChefLicensing::Context.license = ChefLicensing.client(license_keys: [license_key])
  end
end
