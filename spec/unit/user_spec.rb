#
# Author:: Steven Danna (steve@opscode.com)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'spec_helper'

require 'chef/user'
require 'tempfile'

describe Chef::User do
  before(:each) do
    @user = Chef::User.new
  end

  shared_examples_for "string fields with no contraints" do
    it "should let you set the public key" do
      expect(@user.send(method, "some_string")).to eq("some_string")
    end

    it "should return the current public key" do
      @user.send(method, "some_string")
      expect(@user.send(method)).to eq("some_string")
    end

    it "should throw an ArgumentError if you feed it something lame" do
      expect { @user.send(method, Hash.new) }.to raise_error(ArgumentError)
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

    it "should throw an ArgumentError if you feed it anything but true or false" do
      expect { @user.send(method, Hash.new) }.to raise_error(ArgumentError)
    end
  end

  describe "initialize" do
    it "should be a Chef::User" do
      expect(@user).to be_a_kind_of(Chef::User)
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
      expect { @user.username Hash.new }.to raise_error(ArgumentError)
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
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :public_key }
      end
    end

    describe "private_key" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :private_key }
      end
    end

    describe "display_name" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :display_name }
      end
    end

    describe "first_name" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :first_name }
      end
    end

    describe "middle_name" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :middle_name }
      end
    end

    describe "last_name" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :last_name }
      end
    end

    describe "email" do
      it_should_behave_like "string fields with no contraints" do
        let(:method) { :email }
      end
    end

    describe "password" do
      it_should_behave_like "string fields with no contraints" do
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

    it "does not include the display name if not present" do
      expect(@json).not_to include("display_name")
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

    include_examples "to_json equalivent to Chef::JSONCompat.to_json" do
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
        "create_key" => true
      }
      @user = Chef::User.from_json(Chef::JSONCompat.to_json(user))
    end

    it "should deserialize to a Chef::User object" do
      expect(@user).to be_a_kind_of(Chef::User)
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

    it "includes the create key status if present" do
      expect(@user.create_key).to be_truthy
    end
  end

  describe "Versioned API Interactions" do
    let(:response_406) { OpenStruct.new(:code => '406') }
    let(:exception_406) { Net::HTTPServerException.new("406 Not Acceptable", response_406) }

    before (:each) do
      @user = Chef::User.new
      allow(@user).to receive(:chef_root_rest_v0).and_return(double('chef rest root v0 object'))
      allow(@user).to receive(:chef_root_rest_v1).and_return(double('chef rest root v1 object'))
    end

    shared_examples_for "version handling" do
      before do
        allow(@user.chef_root_rest_v1).to receive(http_verb).and_raise(exception_406)
      end

      context "when the server does not support the min or max server API version that Chef::User supports" do
        before do
          allow(@user).to receive(:handle_version_http_exception).and_return(false)
        end

        it "raises the original exception" do
          expect{ @user.send(method) }.to raise_error(exception_406)
        end
      end # when the server does not support the min or max server API version that Chef::User supports
    end # version handling

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

      let(:payload) {
        {
          :username => "some_username",
          :display_name => "some_display_name",
          :first_name => "some_first_name",
          :middle_name => "some_middle_name",
          :last_name => "some_last_name",
          :email => "some_email",
          :password => "some_password"
        }
      }

      context "when server API V1 is valid on the Chef Server receiving the request" do
        context "when the user submits valid data" do
          it "properly updates the user" do
            expect(@user.chef_root_rest_v1).to receive(:put).with("users/some_username", payload).and_return({})
            @user.update
          end
        end
      end

      context "when server API V1 is not valid on the Chef Server receiving the request" do
        let(:payload) {
          {
            :username => "some_username",
            :display_name => "some_display_name",
            :first_name => "some_first_name",
            :middle_name => "some_middle_name",
            :last_name => "some_last_name",
            :email => "some_email",
            :password => "some_password",
            :public_key => "some_public_key"
          }
        }

        before do
          @user.public_key "some_public_key"
          allow(@user.chef_root_rest_v1).to receive(:put)
        end

        context "when the server returns a 400" do
          let(:response_400) { OpenStruct.new(:code => '400') }
          let(:exception_400) { Net::HTTPServerException.new("400 Bad Request", response_400) }

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

            it "does not call handle_version_http_exception, since we know to proceed with V0 in this case" do
              expect(@user).to_not receive(:handle_version_http_exception)
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
          it_should_behave_like "version handling" do
            let(:method)    { (:update) }
            let(:http_verb) { (:put) }
          end

          context "when the server supports API V0" do
            before do
              allow(@user).to receive(:handle_version_http_exception).and_return(true)
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
      let(:payload) {
        {
          :username => "some_username",
          :display_name => "some_display_name",
          :first_name => "some_first_name",
          :last_name => "some_last_name",
          :email => "some_email",
          :password => "some_password"
        }
      }
      before do
        @user.username "some_username"
        @user.display_name "some_display_name"
        @user.first_name "some_first_name"
        @user.last_name "some_last_name"
        @user.email "some_email"
        @user.password "some_password"
      end

      shared_examples_for "create valid user" do
        it "creates a new user via the API" do
          expect(chef_rest_object).to receive(:post).with("users", payload).and_return({})
          @user.create
        end

        it "creates a new user via the API with a public_key when it exists" do
          @user.public_key "some_public_key"
          expect(chef_rest_object).to receive(:post).with("users", payload.merge({:public_key => "some_public_key"})).and_return({})
          @user.create
        end

        it "creates a new user via the API with a middle_name when it exists" do
          @user.middle_name "some_middle_name"
          expect(chef_rest_object).to receive(:post).with("users", payload.merge({:middle_name => "some_middle_name"})).and_return({})
          @user.create
        end
      end

      context "when server API V1 is valid on the Chef Server receiving the request" do
        context "when create_key and public_key are both set" do
          before do
            @user.public_key "key"
            @user.create_key true
          end
          it "rasies a Chef::Exceptions::InvalidUserAttribute" do
            expect { @user.create }.to raise_error(Chef::Exceptions::InvalidUserAttribute)
          end
        end

        it_should_behave_like "create valid user" do
          let(:chef_rest_object) { @user.chef_root_rest_v1 }
        end

        it "creates a new user via the API with create_key == true when it exists" do
          @user.create_key true
          expect(@user.chef_root_rest_v1).to receive(:post).with("users", payload.merge({:create_key => true})).and_return({})
          @user.create
        end

        context "when chef_key is returned by the server" do
          let(:chef_key) {
            {
              "chef_key" => {
                "public_key" => "some_public_key"
              }
            }
          }

          it "puts the public key into the user returned by create" do
            expect(@user.chef_root_rest_v1).to receive(:post).with("users", payload).and_return(payload.merge(chef_key))
            new_user = @user.create
            expect(new_user.public_key).to eq("some_public_key")
          end

          context "when private_key is returned in chef_key" do
            let(:chef_key) {
              {
                "chef_key" => {
                  "public_key" => "some_public_key",
                  "private_key" => "some_private_key"
                }
              }
            }

            it "puts the private key into the user returned by create" do
              expect(@user.chef_root_rest_v1).to receive(:post).with("users", payload).and_return(payload.merge(chef_key))
              new_user = @user.create
              expect(new_user.private_key).to eq("some_private_key")
            end
          end

        end # when chef_key is returned by the server
      end # when server API V1 is valid on the Chef Server receiving the request

      context "when server API V1 is not valid on the Chef Server receiving the request" do
        it_should_behave_like "version handling" do
          let(:method)    { (:create) }
          let(:http_verb) { (:post) }
        end

        context "when the server supports API V0" do
          before do
            allow(@user).to receive(:handle_version_http_exception).and_return(true)
            allow(@user.chef_root_rest_v1).to receive(:post).and_raise(exception_406)
          end

          it_should_behave_like "create valid user" do
            let(:chef_rest_object) { @user.chef_root_rest_v0 }
          end

        end # when the server supports API V0
      end # when server API V1 is not valid on the Chef Server receiving the request
    end # create

  end # Versioned API Interactions

  describe "API Interactions" do
    before (:each) do
      @user = Chef::User.new
      @user.username "foobar"
      @http_client = double("Chef::REST mock")
      allow(Chef::REST).to receive(:new).and_return(@http_client)
    end

    describe "list" do
      before(:each) do
        Chef::Config[:chef_server_url] = "http://www.example.com"
        @osc_response = { "admin" => "http://www.example.com/users/admin"}
        @ohc_response = [ { "user" => { "username" => "admin" }} ]
        allow(Chef::User).to receive(:load).with("admin").and_return(@user)
        @osc_inflated_response = { "admin" => @user }
      end

      it "lists all clients on an OHC/OPC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@ohc_response)
        # We expect that Chef::User.list will give a consistent response
        # so OHC API responses should be transformed to OSC-style output.
        expect(Chef::User.list).to eq(@osc_response)
      end

      it "inflate all clients on an OHC/OPC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@ohc_response)
        expect(Chef::User.list(true)).to eq(@osc_inflated_response)
      end
    end

    describe "read" do
      it "loads a named user from the API" do
        expect(@http_client).to receive(:get).with("users/foobar").and_return({"username" => "foobar", "admin" => true, "public_key" => "pubkey"})
        user = Chef::User.load("foobar")
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
