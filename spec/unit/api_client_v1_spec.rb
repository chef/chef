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

require "chef/api_client_v1"
require "tempfile"

describe Chef::ApiClientV1 do
  before(:each) do
    @client = Chef::ApiClientV1.new
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

  it "has an create_key flag attribute" do
    @client.create_key(true)
    expect(@client.create_key).to be_truthy
  end

  it "create_key defaults to false" do
    expect(@client.create_key).to be_falsey
  end

  it "allows only boolean values for the create_key flag" do
    expect { @client.create_key(false) }.not_to raise_error
    expect { @client.create_key(Hash.new) }.to raise_error(ArgumentError)
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

    it "includes the 'create_key' flag when present" do
      @client.create_key(true)
      @json = @client.to_json
      expect(@json).to include(%q{"create_key":true})
    end

    it "includes the private key when present" do
      @client.private_key("monkeypants")
      expect(@client.to_json).to include(%q{"private_key":"monkeypants"})
    end

    it "does not include the private key if not present" do
      expect(@json).not_to include("private_key")
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @client }
    end
  end

  describe "when deserializing from JSON (string) using ApiClient#from_json" do
    let(:client_string) do
      "{\"name\":\"black\",\"public_key\":\"crowes\",\"private_key\":\"monkeypants\",\"admin\":true,\"validator\":true,\"create_key\":true}"
    end

    let(:client) do
      Chef::ApiClientV1.from_json(client_string)
    end

    it "does not require a 'json_class' string" do
      expect(Chef::JSONCompat.parse(client_string)["json_class"]).to eq(nil)
    end

    it "should deserialize to a Chef::ApiClientV1 object" do
      expect(client).to be_a_kind_of(Chef::ApiClientV1)
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

    it "preserves the create_key status" do
      expect(client.create_key).to be_truthy
    end

    it "preserves the 'validator' status" do
      expect(client.validator).to be_truthy
    end

    it "includes the private key if present" do
      expect(client.private_key).to eq("monkeypants")
    end
  end

  describe "when deserializing from JSON (hash) using ApiClientV1#from_json" do
    let(:client_hash) do
      {
        "name" => "black",
        "public_key" => "crowes",
        "private_key" => "monkeypants",
        "admin" => true,
        "validator" => true,
        "create_key" => true,
      }
    end

    let(:client) do
      Chef::ApiClientV1.from_json(Chef::JSONCompat.to_json(client_hash))
    end

    it "should deserialize to a Chef::ApiClientV1 object" do
      expect(client).to be_a_kind_of(Chef::ApiClientV1)
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

    it "preserves the create_key status" do
      expect(client.create_key).to be_truthy
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
        "create_key" => true,
        "validator" => true,
      }

      @http_client = double("Chef::ServerAPI mock")
      allow(Chef::ServerAPI).to receive(:new).and_return(@http_client)
      expect(@http_client).to receive(:get).with("clients/black").and_return(client)
      @client = Chef::ApiClientV1.load(client["name"])
    end

    it "should deserialize to a Chef::ApiClientV1 object" do
      expect(@client).to be_a_kind_of(Chef::ApiClientV1)
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

    it "preserves the create_key status" do
      expect(@client.create_key).to be_a_kind_of(TrueClass)
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
        expect { Chef::ApiClientV1.reregister("lost-my-key") }.to raise_error(Net::HTTPServerException)
      end
    end
  end

  describe "Versioned API Interactions" do
    let(:response_406) { OpenStruct.new(:code => "406") }
    let(:exception_406) { Net::HTTPServerException.new("406 Not Acceptable", response_406) }
    let(:payload) do
      {
        :name => "some_name",
        :validator => true,
        :admin => true,
      }
    end

    before do
      @client = Chef::ApiClientV1.new
      allow(@client).to receive(:chef_rest_v0).and_return(double("chef rest root v0 object"))
      allow(@client).to receive(:chef_rest_v1).and_return(double("chef rest root v1 object"))
      @client.name "some_name"
      @client.validator true
      @client.admin true
    end

    describe "create" do

      # from spec/support/shared/unit/user_and_client_shared.rb
      it_should_behave_like "user or client create" do
        let(:object)  { @client }
        let(:error)   { Chef::Exceptions::InvalidClientAttribute }
        let(:rest_v0) { @client.chef_rest_v0 }
        let(:rest_v1) { @client.chef_rest_v1 }
        let(:url)     { "clients" }
      end

      context "when API V1 is not supported by the server" do
        # from spec/support/shared/unit/api_versioning.rb
        it_should_behave_like "version handling" do
          let(:object)    { @client }
          let(:method)    { :create }
          let(:http_verb) { :post }
          let(:rest_v1)   { @client.chef_rest_v1 }
        end
      end

    end # create

    describe "update" do
      context "when a valid client is defined" do

        shared_examples_for "client updating" do
          it "updates the client" do
            expect(rest). to receive(:put).with("clients/some_name", payload).and_return(payload)
            @client.update
          end

          context "when only the name field exists" do

            before do
              # needed since there is no way to set to nil via code
              @client.instance_variable_set(:@validator, nil)
              @client.instance_variable_set(:@admin, nil)
            end

            after do
              @client.validator true
              @client.admin true
            end

            it "updates the client with only the name" do
              expect(rest). to receive(:put).with("clients/some_name", { :name => "some_name" }).and_return({ :name => "some_name" })
              @client.update
            end
          end

        end

        context "when API V1 is supported by the server" do

          it_should_behave_like "client updating" do
            let(:rest) { @client.chef_rest_v1 }
          end

        end # when API V1 is supported by the server

        context "when API V1 is not supported by the server" do
          context "when no version is supported" do
            # from spec/support/shared/unit/api_versioning.rb
            it_should_behave_like "version handling" do
              let(:object)    { @client }
              let(:method)    { :create }
              let(:http_verb) { :post }
              let(:rest_v1)   { @client.chef_rest_v1 }
            end
          end # when no version is supported

          context "when API V0 is supported" do

            before do
              allow(@client.chef_rest_v1).to receive(:put).and_raise(exception_406)
              allow(@client).to receive(:server_client_api_version_intersection).and_return([0])
            end

            it_should_behave_like "client updating" do
              let(:rest) { @client.chef_rest_v0 }
            end

          end

        end # when API V1 is not supported by the server
      end # when a valid client is defined
    end # update

    # DEPRECATION
    # This can be removed after API V0 support is gone
    describe "reregister" do
      context "when server API V0 is valid on the Chef Server receiving the request" do
        it "creates a new object via the API" do
          expect(@client.chef_rest_v0).to receive(:put).with("clients/#{@client.name}", payload.merge({ :private_key => true })).and_return({})
          @client.reregister
        end
      end # when server API V0 is valid on the Chef Server receiving the request

      context "when server API V0 is not supported by the Chef Server" do
        # from spec/support/shared/unit/api_versioning.rb
        it_should_behave_like "user and client reregister" do
          let(:object)    { @client }
          let(:rest_v0)   { @client.chef_rest_v0 }
        end
      end # when server API V0 is not supported by the Chef Server
    end # reregister

  end
end
