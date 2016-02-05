#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/api_client"
require "tempfile"

# DEPRECATION NOTE
#
# This code will be removed in Chef 13 in favor of the code in Chef::ApiClientV1,
# which will be moved to this namespace. New development should occur in
# Chef::ApiClientV1 until the time before Chef 13.
describe Chef::ApiClient do
  before(:each) do
    @client = Chef::ApiClient.new
  end

  it "has a name attribute" do
    @client.name("ops_master")
    expect(@client.name).to eq("ops_master")
  end

  it "does not allow spaces in the name" do
    expect { @client.name "ops master" }.to raise_error(ArgumentError)
  end

  it "only allows string values for the name" do
    expect { @client.name Hash.new }.to raise_error(ArgumentError)
  end

  it "has an admin flag attribute" do
    @client.admin(true)
    expect(@client.admin).to be_truthy
  end

  it "defaults to non-admin" do
    expect(@client.admin).to be_falsey
  end

  it "allows only boolean values for the admin flag" do
    expect { @client.admin(false) }.not_to raise_error
    expect { @client.admin(Hash.new) }.to raise_error(ArgumentError)
  end

  it "has a 'validator' flag attribute" do
    @client.validator(true)
    expect(@client.validator).to be_truthy
  end

  it "defaults to non-validator" do
    expect(@client.validator).to be_falsey
  end

  it "allows only boolean values for the 'validator' flag" do
    expect { @client.validator(false) }.not_to raise_error
    expect { @client.validator(Hash.new) }.to raise_error(ArgumentError)
  end

  it "has a public key attribute" do
    @client.public_key("super public")
    expect(@client.public_key).to eq("super public")
  end

  it "accepts only String values for the public key" do
    expect { @client.public_key "" }.not_to raise_error
    expect { @client.public_key Hash.new }.to raise_error(ArgumentError)
  end

  it "has a private key attribute" do
    @client.private_key("super private")
    expect(@client.private_key).to eq("super private")
  end

  it "accepts only String values for the private key" do
    expect { @client.private_key "" }.not_to raise_error
    expect { @client.private_key Hash.new }.to raise_error(ArgumentError)
  end

  describe "when serializing to JSON" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @json = @client.to_json
    end

    it "serializes as a JSON object" do
      expect(@json).to match(/^\{.+\}$/)
    end

    it "includes the name value" do
      expect(@json).to include(%q{"name":"black"})
    end

    it "includes the public key value" do
      expect(@json).to include(%{"public_key":"crowes"})
    end

    it "includes the 'admin' flag" do
      expect(@json).to include(%q{"admin":false})
    end

    it "includes the 'validator' flag" do
      expect(@json).to include(%q{"validator":false})
    end

    it "includes the private key when present" do
      @client.private_key("monkeypants")
      expect(@client.to_json).to include(%q{"private_key":"monkeypants"})
    end

    it "does not include the private key if not present" do
      expect(@json).not_to include("private_key")
    end
  end

  describe "when deserializing from JSON (string) using ApiClient#from_json" do
    let(:client_string) do
      "{\"name\":\"black\",\"public_key\":\"crowes\",\"private_key\":\"monkeypants\",\"admin\":true,\"validator\":true}"
    end

    let(:client) do
      Chef::ApiClient.from_json(client_string)
    end

    it "does not require a 'json_class' string" do
      expect(Chef::JSONCompat.parse(client_string)["json_class"]).to eq(nil)
    end

    it "should deserialize to a Chef::ApiClient object" do
      expect(client).to be_a_kind_of(Chef::ApiClient)
    end

    it "preserves the name" do
      expect(client.name).to eq("black")
    end

    it "preserves the public key" do
      expect(client.public_key).to eq("crowes")
    end

    it "preserves the admin status" do
      expect(client.admin).to be_truthy
    end

    it "preserves the 'validator' status" do
      expect(client.validator).to be_truthy
    end

    it "includes the private key if present" do
      expect(client.private_key).to eq("monkeypants")
    end
  end

  describe "when deserializing from JSON (hash) using JSONCompat#from_json" do
    let(:client_hash) do
      {
        "name" => "black",
        "public_key" => "crowes",
        "private_key" => "monkeypants",
        "admin" => true,
        "validator" => true,
        "json_class" => "Chef::ApiClient",
      }
    end

    let(:client) do
      Chef::ApiClient.from_hash(Chef::JSONCompat.parse(Chef::JSONCompat.to_json(client_hash)))
    end

    it "should deserialize to a Chef::ApiClient object" do
      expect(client).to be_a_kind_of(Chef::ApiClient)
    end

    it "preserves the name" do
      expect(client.name).to eq("black")
    end

    it "preserves the public key" do
      expect(client.public_key).to eq("crowes")
    end

    it "preserves the admin status" do
      expect(client.admin).to be_truthy
    end

    it "preserves the 'validator' status" do
      expect(client.validator).to be_truthy
    end

    it "includes the private key if present" do
      expect(client.private_key).to eq("monkeypants")
    end
  end

  describe "when loading from JSON" do
    before do
    end

    before(:each) do
      client = {
      "name" => "black",
      "clientname" => "black",
      "public_key" => "crowes",
      "private_key" => "monkeypants",
      "admin" => true,
      "validator" => true,
      "json_class" => "Chef::ApiClient",
      }
      @http_client = double("Chef::ServerAPI mock")
      allow(Chef::ServerAPI).to receive(:new).and_return(@http_client)
      expect(@http_client).to receive(:get).with("clients/black").and_return(client)
      @client = Chef::ApiClient.load(client["name"])
    end

    it "should deserialize to a Chef::ApiClient object" do
      expect(@client).to be_a_kind_of(Chef::ApiClient)
    end

    it "preserves the name" do
      expect(@client.name).to eq("black")
    end

    it "preserves the public key" do
      expect(@client.public_key).to eq("crowes")
    end

    it "preserves the admin status" do
      expect(@client.admin).to be_a_kind_of(TrueClass)
    end

    it "preserves the 'validator' status" do
      expect(@client.validator).to be_a_kind_of(TrueClass)
    end

    it "includes the private key if present" do
      expect(@client.private_key).to eq("monkeypants")
    end

  end

  describe "with correctly configured API credentials" do
    before do
      Chef::Config[:node_name] = "silent-bob"
      Chef::Config[:client_key] = File.expand_path("ssl/private_key.pem", CHEF_SPEC_DATA)
    end

    after do
      Chef::Config[:node_name] = nil
      Chef::Config[:client_key] = nil
    end

    let :private_key_data do
      File.open(Chef::Config[:client_key], "r") { |f| f.read.chomp }
    end

  end

  describe "when requesting a new key" do
    before do
      @http_client = double("Chef::ServerAPI mock")
      allow(Chef::ServerAPI).to receive(:new).and_return(@http_client)
    end

    context "and the client does not exist on the server" do
      before do
        @a_404_response = Net::HTTPNotFound.new("404 not found and such", nil, nil)
        @a_404_exception = Net::HTTPServerException.new("404 not found exception", @a_404_response)

        expect(@http_client).to receive(:get).with("clients/lost-my-key").and_raise(@a_404_exception)
      end

      it "raises a 404 error" do
        expect { Chef::ApiClient.reregister("lost-my-key") }.to raise_error(Net::HTTPServerException)
      end
    end

    context "and the client exists" do
      before do
        @api_client_without_key = Chef::ApiClient.new
        @api_client_without_key.name("lost-my-key")
        expect(@http_client).to receive(:get).with("clients/lost-my-key").and_return(@api_client_without_key)
      end

      context "and the client exists on a Chef 11-like server" do
        before do
          @api_client_with_key = Chef::ApiClient.new
          @api_client_with_key.name("lost-my-key")
          @api_client_with_key.private_key("the new private key")
          expect(@http_client).to receive(:put).
            with("clients/lost-my-key", :name => "lost-my-key", :admin => false, :validator => false, :private_key => true).
            and_return(@api_client_with_key)
        end

        it "returns an ApiClient with a private key" do
          response = Chef::ApiClient.reregister("lost-my-key")
          # no sane == method for ApiClient :'(
          expect(response).to eq(@api_client_without_key)
          expect(response.private_key).to eq("the new private key")
          expect(response.name).to eq("lost-my-key")
          expect(response.admin).to be_falsey
        end
      end

      context "and the client exists on a Chef 10-like server" do
        before do
          @api_client_with_key = { "name" => "lost-my-key", "private_key" => "the new private key" }
          expect(@http_client).to receive(:put).
            with("clients/lost-my-key", :name => "lost-my-key", :admin => false, :validator => false, :private_key => true).
            and_return(@api_client_with_key)
        end

        it "returns an ApiClient with a private key" do
          response = Chef::ApiClient.reregister("lost-my-key")
          # no sane == method for ApiClient :'(
          expect(response).to eq(@api_client_without_key)
          expect(response.private_key).to eq("the new private key")
          expect(response.name).to eq("lost-my-key")
          expect(response.admin).to be_falsey
          expect(response.validator).to be_falsey
        end
      end

    end
  end
end
