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

require 'chef/user_v1'
require 'tempfile'

describe Chef::UserV1 do
  before(:each) do
    @user = Chef::UserV1.new
  end

  describe "initialize" do
    it "should be a Chef::UserV1" do
      expect(@user).to be_a_kind_of(Chef::UserV1)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      expect(@user.name("ops_master")).to eq("ops_master")
    end

    it "should return the current name" do
      @user.name "ops_master"
      expect(@user.name).to eq("ops_master")
    end

    # It is not feasible to check all invalid characters.  Here are a few
    # that we probably care about.
    it "should not accept invalid characters" do
      # capital letters
      expect { @user.name "Bar" }.to raise_error(ArgumentError)
      # slashes
      expect { @user.name "foo/bar" }.to raise_error(ArgumentError)
      # ?
      expect { @user.name "foo?" }.to raise_error(ArgumentError)
      # &
      expect { @user.name "foo&" }.to raise_error(ArgumentError)
    end


    it "should not accept spaces" do
      expect { @user.name "ops master" }.to raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      expect { @user.name Hash.new }.to raise_error(ArgumentError)
    end
  end

  describe "admin" do
    it "should let you set the admin bit" do
      expect(@user.admin(true)).to eq(true)
    end

    it "should return the current admin value" do
      @user.admin true
      expect(@user.admin).to eq(true)
    end

    it "should default to false" do
      expect(@user.admin).to eq(false)
    end

    it "should throw an ArgumentError if you feed it anything but true or false" do
      expect { @user.name Hash.new }.to raise_error(ArgumentError)
    end
  end

  describe "private_key" do
    it "should let you set the private key" do
      expect(@user.private_key("super private")).to eq("super private")
    end

    it "should return the private key" do
      @user.private_key("super private")
      expect(@user.private_key).to eq("super private")
    end

    it "should throw an ArgumentError if you feed it something lame" do
      expect { @user.private_key Hash.new }.to raise_error(ArgumentError)
    end
  end

  describe "when serializing to JSON" do
    before(:each) do
      @user.name("black")
      @json = @user.to_json
    end

    it "serializes as a JSON object" do
      expect(@json).to match(/^\{.+\}$/)
    end

    it "includes the name value" do
      expect(@json).to include(%q{"name":"black"})
    end

    it "includes the 'admin' flag" do
      expect(@json).to include(%q{"admin":false})
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
        "name" => "mr_spinks",
        "private_key" => "pandas",
        "password" => "password",
        "admin" => true
      }
      @user = Chef::UserV1.from_json(Chef::JSONCompat.to_json(user))
    end

    it "should deserialize to a Chef::UserV1 object" do
      expect(@user).to be_a_kind_of(Chef::UserV1)
    end

    it "preserves the name" do
      expect(@user.name).to eq("mr_spinks")
    end

    it "preserves the admin status" do
      expect(@user.admin).to be_truthy
    end

    it "includes the private key if present" do
      expect(@user.private_key).to eq("pandas")
    end

    it "includes the password if present" do
      expect(@user.password).to eq("password")
    end

  end

  describe "API Interactions" do
    before (:each) do
      @user = Chef::UserV1.new
      @user.name "foobar"
      @http_client = double("Chef::REST mock")
      allow(Chef::REST).to receive(:new).and_return(@http_client)
    end

    describe "list" do
      before(:each) do
        Chef::Config[:chef_server_url] = "http://www.example.com"
        @osc_response = { "admin" => "http://www.example.com/users/admin"}
        @ohc_response = [ { "user" => { "username" => "admin" }} ]
        allow(Chef::UserV1).to receive(:load).with("admin").and_return(@user)
        @osc_inflated_response = { "admin" => @user }
      end

      it "lists all clients on an OSC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@osc_response)
        expect(Chef::UserV1.list).to eq(@osc_response)
      end

      it "inflate all clients on an OSC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@osc_response)
        expect(Chef::UserV1.list(true)).to eq(@osc_inflated_response)
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

    describe "create" do
      before do
        @user.password "password"
      end

      it "creates a new user via the API" do
        expect(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password"}).and_return({})
        @user.create
      end

      context "when an initial_public_key is passed in and create_key is true" do
        before do
          @user.create_key true
        end
        it "raises Chef::Exceptions::InvalidUserAttribute" do
          expect{ @user.create("some_public_key") }.to raise_error(Chef::Exceptions::InvalidUserAttribute)
        end
      end
      context "when initial_public_key isn't passed and create_key isn't set" do
        it "posts a valid user" do
          expect(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password"}).and_return({})
          @user.create
        end
      end

      context "when initial_public_key is passed and create_key isn't set" do
        let(:public_key_string) { "some_public_key" }
        let(:returned_key_string) { "returned_public_key" }
        let(:expected_data) {
          {
            "name" => "foobar",
            "admin" => false,
            "password" => "password"
          }
        }
        let(:returned_data) {
          {
            "name" => "foobar",
            "admin" => false,
            "password" => "password",
            "chef_key" => {
              "name" => "default",
              "public_key" => returned_key_string
            }
          }
        }
        it "posts a valid user" do
          expect(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password", :public_key => public_key_string}).and_return({})
          @user.create(public_key_string)
        end

        it "properly parses the chef_key returned by the server" do
          allow(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password", :public_key => public_key_string}).and_return(returned_data)
          expect(Chef::UserV1).to receive(:from_hash).with(expected_data)
          @user.create(public_key_string)
        end
      end

      context "when initial_public_key isn't passed and create_key is true" do
        let(:returned_key_string) { "returned_public_key" }
        let(:private_key_string) { "private_key" }
        let(:expected_data) {
          {
            "name" => "foobar",
            "admin" => false,
            "password" => "password",
            "private_key" => private_key_string
          }
        }
        let(:returned_data) {
          {
            "name" => "foobar",
            "admin" => false,
            "password" => "password",
            "chef_key" => {
              "name" => "default",
              "public_key" => returned_key_string,
              "private_key" => private_key_string
            }
          }
        }

        before do
          @user.create_key true
        end

        it "posts a valid user" do
          expect(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password", :create_key => true}).and_return({})
          @user.create
        end

        it "properly parses the chef_key returned by the server" do
          allow(@http_client).to receive(:post).with("users", {:name => "foobar", :admin => false, :password => "password", :create_key => true}).and_return(returned_data)
          expect(Chef::UserV1).to receive(:from_hash).with(expected_data)
          @user.create
        end
      end
    end

    describe "read" do
      it "loads a named user from the API" do
        expect(@http_client).to receive(:get).with("users/foobar").and_return({"name" => "foobar", "admin" => true})
        user = Chef::UserV1.load("foobar")
        expect(user.name).to eq("foobar")
        expect(user.admin).to eq(true)
      end
    end

    describe "update" do
      it "updates an existing user on via the API" do
        expect(@http_client).to receive(:put).with("users/foobar", {:name => "foobar", :admin => false}).and_return({})
        @user.update
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
