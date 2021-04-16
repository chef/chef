#
# Author:: Steven Danna (steve@chef.io)
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef/user_v1"
require "tempfile"

describe Chef::UserV1 do
  before(:each) do
    @user = Chef::UserV1.new
  end

  shared_examples_for "string fields with no constraints" do
    it "should let you set the public key" do
      expect(@user.send(method, "some_string")).to eq("some_string")
    end

    it "should return the current public key" do
      @user.send(method, "some_string")
      expect(@user.send(method)).to eq("some_string")
    end

    it "should throw an ArgumentError if you feed it something lame" do
      expect { @user.send(method, {}) }.to raise_error(ArgumentError)
    end
  end

  shared_examples_for "boolean fields with no constraints" do
    it "should let you set the field" do
      expect(@user.send(method, true)).to eq(true)
    end

    it "should return the current field value" do
      @user.send(method, true)
      expect(@user.send(method)).to eq(true)
    end

    it "should return the false value when false" do
      @user.send(method, false)
      expect(@user.send(method)).to eq(false)
    end

    it "should throw an ArgumentError if you feed it anything but true or false" do
      expect { @user.send(method, {}) }.to raise_error(ArgumentError)
    end
  end

  describe "initialize" do
    it "should be a Chef::UserV1" do
      expect(@user).to be_a_kind_of(Chef::UserV1)
    end
  end

  describe "username" do
    it "should let you set the username to a string" do
      expect(@user.username("ops_master")).to eq("ops_master")
    end

    it "should return the current username" do
      @user.username "ops_master"
      expect(@user.username).to eq("ops_master")
    end

    # It is not feasible to check all invalid characters.  Here are a few
    # that we probably care about.
    it "should not accept invalid characters" do
      # capital letters
      expect { @user.username "Bar" }.to raise_error(ArgumentError)
      # slashes
      expect { @user.username "foo/bar" }.to raise_error(ArgumentError)
      # ?
      expect { @user.username "foo?" }.to raise_error(ArgumentError)
      # &
      expect { @user.username "foo&" }.to raise_error(ArgumentError)
    end

    it "should not accept spaces" do
      expect { @user.username "ops master" }.to raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      expect { @user.username({}) }.to raise_error(ArgumentError)
    end
  end

  describe "boolean fields" do
    describe "create_key" do
      it_should_behave_like "boolean fields with no constraints" do
        let(:method) { :create_key }
      end
    end
  end

  describe "string fields" do
    describe "public_key" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :public_key }
      end
    end

    describe "private_key" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :private_key }
      end
    end

    describe "display_name" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :display_name }
      end
    end

    describe "first_name" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :first_name }
      end
    end

    describe "middle_name" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :middle_name }
      end
    end

    describe "last_name" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :last_name }
      end
    end

    describe "email" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :email }
      end
    end

    describe "password" do
      it_should_behave_like "string fields with no constraints" do
        let(:method) { :password }
      end
    end
  end

  describe "when serializing to JSON" do
    before(:each) do
      @user.username("black")
      @json = @user.to_json
    end

    it "serializes as a JSON object" do
      expect(@json).to match(/^\{.+\}$/)
    end

    it "includes the username value" do
      expect(@json).to include(%q{"username":"black"})
    end

    it "includes the display name when present" do
      @user.display_name("get_displayed")
      expect(@user.to_json).to include(%{"display_name":"get_displayed"})
    end

    it "does not include the display name if user name not present" do
      unless @user.username
        expect(@json).not_to include("display_name")
      end
    end

    it "includes the first name when present" do
      @user.first_name("char")
      expect(@user.to_json).to include(%{"first_name":"char"})
    end

    it "does not include the first name if not present" do
      expect(@json).not_to include("first_name")
    end

    it "includes the middle name when present" do
      @user.middle_name("man")
      expect(@user.to_json).to include(%{"middle_name":"man"})
    end

    it "does not include the middle name if not present" do
      expect(@json).not_to include("middle_name")
    end

    it "includes the last name when present" do
      @user.last_name("der")
      expect(@user.to_json).to include(%{"last_name":"der"})
    end

    it "does not include the last name if not present" do
      expect(@json).not_to include("last_name")
    end

    it "includes the email when present" do
      @user.email("charmander@pokemon.poke")
      expect(@user.to_json).to include(%{"email":"charmander@pokemon.poke"})
    end

    it "does not include the email if not present" do
      expect(@json).not_to include("email")
    end

    it "includes the public key when present" do
      @user.public_key("crowes")
      expect(@user.to_json).to include(%{"public_key":"crowes"})
    end

    it "does not include the public key if not present" do
      expect(@json).not_to include("public_key")
    end

    it "includes the private key when present" do
      @user.private_key("monkeypants")
      expect(@user.to_json).to include(%q{"private_key":"monkeypants"})
    end

    it "does not include the private key if not present" do
      expect(@json).not_to include("private_key")
    end

    it "includes the password if present" do
      @user.password "password"
      expect(@user.to_json).to include(%q{"password":"password"})
    end

    it "does not include the password if not present" do
      expect(@json).not_to include("password")
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @user }
    end
  end

  describe "when deserializing from JSON" do
    before(:each) do
      user = {
        "username" => "mr_spinks",
        "display_name" => "displayed",
        "first_name" => "char",
        "middle_name" => "man",
        "last_name" => "der",
        "email" => "charmander@pokemon.poke",
        "password" => "password",
        "public_key" => "turtles",
        "private_key" => "pandas",
        "create_key" => false,
      }
      @user = Chef::UserV1.from_json(Chef::JSONCompat.to_json(user))
    end

    it "should deserialize to a Chef::UserV1 object" do
      expect(@user).to be_a_kind_of(Chef::UserV1)
    end

    it "preserves the username" do
      expect(@user.username).to eq("mr_spinks")
    end

    it "preserves the display name if present" do
      expect(@user.display_name).to eq("displayed")
    end

    it "preserves the first name if present" do
      expect(@user.first_name).to eq("char")
    end

    it "preserves the middle name if present" do
      expect(@user.middle_name).to eq("man")
    end

    it "preserves the last name if present" do
      expect(@user.last_name).to eq("der")
    end

    it "preserves the email if present" do
      expect(@user.email).to eq("charmander@pokemon.poke")
    end

    it "includes the password if present" do
      expect(@user.password).to eq("password")
    end

    it "preserves the public key if present" do
      expect(@user.public_key).to eq("turtles")
    end

    it "includes the private key if present" do
      expect(@user.private_key).to eq("pandas")
    end

    it "includes the create key status if not nil" do
      expect(@user.create_key).to be_falsey
    end
  end

  describe "Versioned API Interactions" do
    let(:response_406) { OpenStruct.new(code: "406") }
    let(:exception_406) { Net::HTTPClientException.new("406 Not Acceptable", response_406) }

    before(:each) do
      @user = Chef::UserV1.new
      allow(@user).to receive(:chef_root_rest_v0).and_return(double("chef rest root v0 object"))
      allow(@user).to receive(:chef_root_rest_v1).and_return(double("chef rest root v1 object"))
    end

    describe "update" do
      before do
        # populate all fields that are valid between V0 and V1
        @user.username "some_username"
        @user.display_name "some_display_name"
        @user.first_name "some_first_name"
        @user.middle_name "some_middle_name"
        @user.last_name "some_last_name"
        @user.email "some_email"
        @user.password "some_password"
      end

      let(:payload) do
        {
          username: "some_username",
          display_name: "some_display_name",
          first_name: "some_first_name",
          middle_name: "some_middle_name",
          last_name: "some_last_name",
          email: "some_email",
          password: "some_password",
        }
      end

      context "when server API V1 is valid on the Chef Server receiving the request" do
        context "when the user submits valid data" do
          it "properly updates the user" do
            expect(@user.chef_root_rest_v1).to receive(:put).with("users/some_username", payload).and_return({})
            @user.update
          end
        end
      end

      context "when server API V1 is not valid on the Chef Server receiving the request" do
        let(:payload) do
          {
            username: "some_username",
            display_name: "some_display_name",
            first_name: "some_first_name",
            middle_name: "some_middle_name",
            last_name: "some_last_name",
            email: "some_email",
            password: "some_password",
            public_key: "some_public_key",
          }
        end

        before do
          @user.public_key "some_public_key"
          allow(@user.chef_root_rest_v1).to receive(:put)
        end

        context "when the server returns a 400" do
          let(:response_400) { OpenStruct.new(code: "400") }
          let(:exception_400) { Net::HTTPClientException.new("400 Bad Request", response_400) }

          context "when the 400 was due to public / private key fields no longer being supported" do
            let(:response_body_400) { '{"error":["Since Server API v1, all keys must be updated via the keys endpoint. "]}' }

            before do
              allow(response_400).to receive(:body).and_return(response_body_400)
              allow(@user.chef_root_rest_v1).to receive(:put).and_raise(exception_400)
            end

            it "proceeds with the V0 PUT since it can handle public / private key fields" do
              expect(@user.chef_root_rest_v0).to receive(:put).with("users/some_username", payload).and_return({})
              @user.update
            end

            it "does not call server_client_api_version_intersection, since we know to proceed with V0 in this case" do
              expect(@user).to_not receive(:server_client_api_version_intersection)
              allow(@user.chef_root_rest_v0).to receive(:put).and_return({})
              @user.update
            end
          end # when the 400 was due to public / private key fields

          context "when the 400 was NOT due to public / private key fields no longer being supported" do
            let(:response_body_400) { '{"error":["Some other error. "]}' }

            before do
              allow(response_400).to receive(:body).and_return(response_body_400)
              allow(@user.chef_root_rest_v1).to receive(:put).and_raise(exception_400)
            end

            it "will not proceed with the V0 PUT since the original bad request was not key related" do
              expect(@user.chef_root_rest_v0).to_not receive(:put).with("users/some_username", payload)
              expect { @user.update }.to raise_error(exception_400)
            end

            it "raises the original error" do
              expect { @user.update }.to raise_error(exception_400)
            end

          end
        end # when the server returns a 400

        context "when the server returns a 406" do
          # from spec/support/shared/unit/api_versioning.rb
          it_should_behave_like "version handling" do
            let(:object)    { @user }
            let(:method)    { :update }
            let(:http_verb) { :put }
            let(:rest_v1)   { @user.chef_root_rest_v1 }
          end

          context "when the server supports API V0" do
            before do
              allow(@user).to receive(:server_client_api_version_intersection).and_return([0])
              allow(@user.chef_root_rest_v1).to receive(:put).and_raise(exception_406)
            end

            it "properly updates the user" do
              expect(@user.chef_root_rest_v0).to receive(:put).with("users/some_username", payload).and_return({})
              @user.update
            end
          end # when the server supports API V0
        end # when the server returns a 406

      end # when server API V1 is not valid on the Chef Server receiving the request
    end # update

    describe "create" do
      let(:payload) do
        {
          username: "some_username",
          display_name: "some_display_name",
          first_name: "some_first_name",
          last_name: "some_last_name",
          email: "some_email",
          password: "some_password",
        }
      end
      before do
        @user.username "some_username"
        @user.display_name "some_display_name"
        @user.first_name "some_first_name"
        @user.last_name "some_last_name"
        @user.email "some_email"
        @user.password "some_password"
      end

      # from spec/support/shared/unit/user_and_client_shared.rb
      it_should_behave_like "user or client create" do
        let(:object)  { @user }
        let(:error)   { Chef::Exceptions::InvalidUserAttribute }
        let(:rest_v0) { @user.chef_root_rest_v0 }
        let(:rest_v1) { @user.chef_root_rest_v1 }
        let(:url)     { "users" }
      end

      context "when handling API V1" do
        it "creates a new user via the API with a middle_name when it exists" do
          @user.middle_name "some_middle_name"
          expect(@user.chef_root_rest_v1).to receive(:post).with("users", payload.merge({ middle_name: "some_middle_name" })).and_return({})
          @user.create
        end
      end # when server API V1 is valid on the Chef Server receiving the request

      context "when API V1 is not supported by the server" do
        # from spec/support/shared/unit/api_versioning.rb
        it_should_behave_like "version handling" do
          let(:object)    { @user }
          let(:method)    { :create }
          let(:http_verb) { :post }
          let(:rest_v1)   { @user.chef_root_rest_v1 }
        end
      end

      context "when handling API V0" do
        before do
          allow(@user).to receive(:server_client_api_version_intersection).and_return([0])
          allow(@user.chef_root_rest_v1).to receive(:post).and_raise(exception_406)
        end

        it "creates a new user via the API with a middle_name when it exists" do
          @user.middle_name "some_middle_name"
          expect(@user.chef_root_rest_v0).to receive(:post).with("users", payload.merge({ middle_name: "some_middle_name" })).and_return({})
          @user.create
        end
      end # when server API V1 is not valid on the Chef Server receiving the request

    end # create

    # DEPRECATION
    # This can be removed after API V0 support is gone
    describe "reregister" do
      let(:payload) do
        {
          "username" => "some_username",
        }
      end

      before do
        @user.username "some_username"
      end

      context "when server API V0 is valid on the Chef Server receiving the request" do
        it "creates a new object via the API" do
          expect(@user.chef_root_rest_v0).to receive(:put).with("users/#{@user.username}", payload.merge({ "private_key" => true })).and_return({})
          @user.reregister
        end
      end # when server API V0 is valid on the Chef Server receiving the request

      context "when server API V0 is not supported by the Chef Server" do
        # from spec/support/shared/unit/api_versioning.rb
        it_should_behave_like "user and client reregister" do
          let(:object)    { @user }
          let(:rest_v0)   { @user.chef_root_rest_v0 }
        end
      end # when server API V0 is not supported by the Chef Server
    end # reregister

  end # Versioned API Interactions

  describe "API Interactions" do
    before(:each) do
      @user = Chef::UserV1.new
      @user.username "foobar"
      @http_client = double("Chef::ServerAPI mock")
      allow(Chef::ServerAPI).to receive(:new).and_return(@http_client)
    end

    describe "list" do
      before(:each) do
        Chef::Config[:chef_server_url] = "http://www.example.com"
        @osc_response = { "admin" => "http://www.example.com/users/admin" }
        @ohc_response = [ { "user" => { "username" => "admin" } } ]
        allow(Chef::UserV1).to receive(:load).with("admin").and_return(@user)
        @osc_inflated_response = { "admin" => @user }
      end

      it "lists all clients on an OHC/OPC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@ohc_response)
        # We expect that Chef::UserV1.list will give a consistent response
        # so OHC API responses should be transformed to OSC-style output.
        expect(Chef::UserV1.list).to eq(@osc_response)
      end

      it "inflate all clients on an OHC/OPC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@ohc_response)
        expect(Chef::UserV1.list(true)).to eq(@osc_inflated_response)
      end
    end

    describe "read" do
      it "loads a named user from the API" do
        expect(@http_client).to receive(:get).with("users/foobar").and_return({ "username" => "foobar", "admin" => true, "public_key" => "pubkey" })
        user = Chef::UserV1.load("foobar")
        expect(user.username).to eq("foobar")
        expect(user.public_key).to eq("pubkey")
      end
    end

    describe "destroy" do
      it "deletes the specified user via the API" do
        expect(@http_client).to receive(:delete).with("users/foobar")
        @user.destroy
      end
    end
  end
end
