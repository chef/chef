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

  describe "initialize" do
    it "should be a Chef::User" do
      @user.should be_a_kind_of(Chef::User)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @user.name("ops_master").should == "ops_master"
    end

    it "should return the current name" do
      @user.name "ops_master"
      @user.name.should == "ops_master"
    end

    # It is not feasible to check all invalid characters.  Here are a few
    # that we probably care about.
    it "should not accept invalid characters" do
      # capital letters
      lambda { @user.name "Bar" }.should raise_error(ArgumentError)
      # slashes
      lambda { @user.name "foo/bar" }.should raise_error(ArgumentError)
      # ?
      lambda { @user.name "foo?" }.should raise_error(ArgumentError)
      # &
      lambda { @user.name "foo&" }.should raise_error(ArgumentError)
    end


    it "should not accept spaces" do
      lambda { @user.name "ops master" }.should raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      lambda { @user.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "admin" do
    it "should let you set the admin bit" do
      @user.admin(true).should == true
    end

    it "should return the current admin value" do
      @user.admin true
      @user.admin.should == true
    end

    it "should default to false" do
      @user.admin.should == false
    end

    it "should throw an ArgumentError if you feed it anything but true or false" do
      lambda { @user.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "public_key" do
    it "should let you set the public key" do
      @user.public_key("super public").should == "super public"
    end

    it "should return the current public key" do
      @user.public_key("super public")
      @user.public_key.should == "super public"
    end

    it "should throw an ArgumentError if you feed it something lame" do
      lambda { @user.public_key Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "private_key" do
    it "should let you set the private key" do
      @user.private_key("super private").should == "super private"
    end

    it "should return the private key" do
      @user.private_key("super private")
      @user.private_key.should == "super private"
    end

    it "should throw an ArgumentError if you feed it something lame" do
      lambda { @user.private_key Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "when serializing to JSON" do
    before(:each) do
      @user.name("black")
      @user.public_key("crowes")
      @json = @user.to_json
    end

    it "serializes as a JSON object" do
      @json.should match(/^\{.+\}$/)
    end

    it "includes the name value" do
      @json.should include(%q{"name":"black"})
    end

    it "includes the public key value" do
      @json.should include(%{"public_key":"crowes"})
    end

    it "includes the 'admin' flag" do
      @json.should include(%q{"admin":false})
    end

    it "includes the private key when present" do
      @user.private_key("monkeypants")
      @user.to_json.should include(%q{"private_key":"monkeypants"})
    end

    it "does not include the private key if not present" do
      @json.should_not include("private_key")
    end

    it "includes the password if present" do
      @user.password "password"
      @user.to_json.should include(%q{"password":"password"})
    end

    it "does not include the password if not present" do
      @json.should_not include("password")
    end
  end

  describe "when deserializing from JSON" do
    before(:each) do
      user = { "name" => "mr_spinks",
        "public_key" => "turtles",
        "private_key" => "pandas",
        "password" => "password",
        "admin" => true }
      @user = Chef::User.from_json(user.to_json)
    end

    it "should deserialize to a Chef::User object" do
      @user.should be_a_kind_of(Chef::User)
    end

    it "preserves the name" do
      @user.name.should == "mr_spinks"
    end

    it "preserves the public key" do
      @user.public_key.should == "turtles"
    end

    it "preserves the admin status" do
      @user.admin.should be_true
    end

    it "includes the private key if present" do
      @user.private_key.should == "pandas"
    end

    it "includes the password if present" do
      @user.password.should == "password"
    end

  end

  describe "API Interactions" do
    before (:each) do
      @user = Chef::User.new
      @user.name "foobar"
      @http_client = mock("Chef::REST mock")
      Chef::REST.stub!(:new).and_return(@http_client)
    end

    describe "list" do
      before(:each) do
        Chef::Config[:chef_server_url] = "http://www.example.com"
        @osc_response = { "admin" => "http://www.example.com/users/admin"}
        @ohc_response = [ { "user" => { "username" => "admin" }} ]
      end

      it "lists all clients on an OSC server" do
        @http_client.stub!(:get_rest).with("users").and_return(@osc_response)
        Chef::User.list.should == @osc_response
      end

      it "lists all clients on an OHC/OPC server" do
        @http_client.stub!(:get_rest).with("users").and_return(@ohc_response)
        # We expect that Chef::User.list will give a consistent response
        # so OHC API responses should be transformed to OSC-style output.
        Chef::User.list.should == @osc_response
      end
    end

    describe "create" do
      it "creates a new user via the API" do
        @user.password "password"
        @http_client.should_receive(:post_rest).with("users", {:name => "foobar", :admin => false, :password => "password"}).and_return({})
        @user.create
      end
    end

    describe "read" do
      it "loads a named user from the API" do
        @http_client.should_receive(:get_rest).with("users/foobar").and_return({"name" => "foobar", "admin" => true, "public_key" => "pubkey"})
        user = Chef::User.load("foobar")
        user.name.should == "foobar"
        user.admin.should == true
        user.public_key.should == "pubkey"
      end
    end

    describe "update" do
      it "updates an existing user on via the API" do
        @http_client.should_receive(:put_rest).with("users/foobar", {:name => "foobar", :admin => false}).and_return({})
        @user.update
      end
    end

    describe "destroy" do
      it "deletes the specified user via the API" do
        @http_client.should_receive(:delete_rest).with("users/foobar")
        @user.destroy
      end
    end
  end
end
