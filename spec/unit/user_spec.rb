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

# DEPRECATION NOTE
# This code only remains to support users still  operating with
# Open Source Chef Server 11 and should be removed once support
# for OSC 11 ends. New development should occur in user_spec.rb.

require "spec_helper"

require "chef/user"
require "tempfile"

describe Chef::User do
  before(:each) do
    @user = Chef::User.new
  end

  describe "initialize" do
    it "should be a Chef::User" do
      expect(@user).to be_a_kind_of(Chef::User)
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
      expect { @user.name({}) }.to raise_error(ArgumentError)
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
      expect { @user.name({}) }.to raise_error(ArgumentError)
    end
  end

  describe "public_key" do
    it "should let you set the public key" do
      expect(@user.public_key("super public")).to eq("super public")
    end

    it "should return the current public key" do
      @user.public_key("super public")
      expect(@user.public_key).to eq("super public")
    end

    it "should throw an ArgumentError if you feed it something lame" do
      expect { @user.public_key({}) }.to raise_error(ArgumentError)
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
      expect { @user.private_key({}) }.to raise_error(ArgumentError)
    end
  end

  describe "when serializing to JSON" do
    before(:each) do
      @user.name("black")
      @user.public_key("crowes")
      @json = @user.to_json
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
      user = { "name" => "mr_spinks",
               "public_key" => "turtles",
               "private_key" => "pandas",
               "password" => "password",
               "admin" => true }
      @user = Chef::User.from_json(Chef::JSONCompat.to_json(user))
    end

    it "should deserialize to a Chef::User object" do
      expect(@user).to be_a_kind_of(Chef::User)
    end

    it "preserves the name" do
      expect(@user.name).to eq("mr_spinks")
    end

    it "preserves the public key" do
      expect(@user.public_key).to eq("turtles")
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
    before(:each) do
      @user = Chef::User.new
      @user.name "foobar"
      @http_client = double("Chef::ServerAPI mock")
      allow(Chef::ServerAPI).to receive(:new).and_return(@http_client)
    end

    describe "list" do
      before(:each) do
        Chef::Config[:chef_server_url] = "http://www.example.com"
        @osc_response = { "admin" => "http://www.example.com/users/admin" }
        @ohc_response = [ { "user" => { "username" => "admin" } } ]
        allow(Chef::User).to receive(:load).with("admin").and_return(@user)
        @osc_inflated_response = { "admin" => @user }
      end

      it "lists all clients on an OSC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@osc_response)
        expect(Chef::User.list).to eq(@osc_response)
      end

      it "inflate all clients on an OSC server" do
        allow(@http_client).to receive(:get).with("users").and_return(@osc_response)
        expect(Chef::User.list(true)).to eq(@osc_inflated_response)
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

    describe "create" do
      it "creates a new user via the API" do
        @user.password "password"
        expect(@http_client).to receive(:post).with("users", { name: "foobar", admin: false, password: "password" }).and_return({})
        @user.create
      end
    end

    describe "read" do
      it "loads a named user from the API" do
        expect(@http_client).to receive(:get).with("users/foobar").and_return({ "name" => "foobar", "admin" => true, "public_key" => "pubkey" })
        user = Chef::User.load("foobar")
        expect(user.name).to eq("foobar")
        expect(user.admin).to eq(true)
        expect(user.public_key).to eq("pubkey")
      end
    end

    describe "update" do
      it "updates an existing user on via the API" do
        expect(@http_client).to receive(:put).with("users/foobar", { name: "foobar", admin: false }).and_return({})
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
