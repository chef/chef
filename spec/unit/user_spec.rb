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
    @client = Chef::User.new
  end

  describe "initialize" do
    it "should be a Chef::User" do
      @client.should be_a_kind_of(Chef::User)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @client.name("ops_master").should == "ops_master"
    end

    it "should return the current name" do
      @client.name "ops_master"
      @client.name.should == "ops_master"
    end

    it "should not accept spaces" do
      lambda { @client.name "ops master" }.should raise_error(ArgumentError)
    end

    it "should throw an ArgumentError if you feed it anything but a string" do
      lambda { @client.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "admin" do
    it "should let you set the admin bit" do
      @client.admin(true).should == true
    end

    it "should return the current admin value" do
      @client.admin true
      @client.admin.should == true
    end

    it "should default to false" do
      @client.admin.should == false
    end

    it "should throw an ArgumentError if you feed it anything but true or false" do
      lambda { @client.name Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "public_key" do
    it "should let you set the public key" do
      @client.public_key("super public").should == "super public"
    end

    it "should return the current public key" do
      @client.public_key("super public")
      @client.public_key.should == "super public"
    end

    it "should throw an ArgumentError if you feed it something lame" do
      lambda { @client.public_key Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "private_key" do
    it "should let you set the private key" do
      @client.private_key("super private").should == "super private"
    end

    it "should return the private key" do
      @client.private_key("super private")
      @client.private_key.should == "super private"
    end

    it "should throw an ArgumentError if you feed it something lame" do
      lambda { @client.private_key Hash.new }.should raise_error(ArgumentError)
    end
  end

  describe "when serializing to JSON" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @json = @client.to_json
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
      @client.private_key("monkeypants")
      @client.to_json.should include(%q{"private_key":"monkeypants"})
    end

    it "does not include the private key if not present" do
      @json.should_not include("private_key")
    end

    it "includes the password if present" do
      @client.password "password"
      @client.to_json.should include(%q{"password":"password"})
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
