#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/api_client'
require 'tempfile'

describe Chef::ApiClient do
  before(:each) do
    @client = Chef::ApiClient.new
  end

  describe "initialize" do
    it "should be a Chef::ApiClient" do
      @client.should be_a_kind_of(Chef::ApiClient)
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

  describe "serialize" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @client.private_key("monkeypants")
      @serial = @client.to_json
    end

    it "should serialize to a json hash" do
      @client.to_json.should match(/^\{.+\}$/)
    end

    %w{
      name
      public_key
    }.each do |t|
      it "should include '#{t}'" do
        @serial.should =~ /"#{t}":"#{@client.send(t.to_sym)}"/
      end
    end

    it "should include 'admin'" do
      @serial.should =~ /"admin":false/
    end

    it "should not include the private key" do
      @serial.should_not =~ /"private_key":/
    end
  end

  describe "deserialize" do
    before(:each) do
      @client.name("black")
      @client.public_key("crowes")
      @client.private_key("monkeypants")
      @client.admin(true)
      @deserial = Chef::JSONCompat.from_json(@client.to_json)
    end

    it "should deserialize to a Chef::ApiClient object" do
      @deserial.should be_a_kind_of(Chef::ApiClient)
    end

    %w{
      name
      public_key
      admin
    }.each do |t|
      it "should match '#{t}'" do
        @deserial.send(t.to_sym).should == @client.send(t.to_sym)
      end
    end

    it "should not include the private key" do
      @deserial.private_key.should == nil
    end

  end

  describe "when requesting a new key" do
    before do
      @http_client = mock("Chef::REST mock")
      Chef::REST.stub!(:new).and_return(@http_client)
    end

    context "and the client does not exist on the server" do
      before do
        @a_404_response = Net::HTTPNotFound.new("404 not found and such", nil, nil)
        @a_404_exception = Net::HTTPServerException.new("404 not found exception", @a_404_response)

        @http_client.should_receive(:get).with("clients/lost-my-key").and_raise(@a_404_exception)
      end
      it "raises a 404 error" do
        lambda { Chef::ApiClient.reregister("lost-my-key") }.should raise_error(@a_404_exception)
      end
    end

    context "and the client exists" do
      before do
        @api_client_without_key = Chef::ApiClient.new
        @api_client_without_key.name("lost-my-key")
        @http_client.should_receive(:get).with("clients/lost-my-key").and_return(@api_client_without_key)
      end


      context "and the client exists on a Chef 11-like server" do
        before do
          @api_client_with_key = Chef::ApiClient.new
          @api_client_with_key.name("lost-my-key")
          @api_client_with_key.private_key("the new private key")
          @http_client.should_receive(:put).
            with("clients/lost-my-key", :name => "lost-my-key", :admin => false, :private_key => true).
            and_return(@api_client_with_key)
        end

        it "returns an ApiClient with a private key" do
          response = Chef::ApiClient.reregister("lost-my-key")
          # no sane == method for ApiClient :'(
          response.should == @api_client_without_key
          response.private_key.should == "the new private key"
          response.name.should == "lost-my-key"
          response.admin.should be_false
        end
      end

      context "and the client exists on a Chef 10-like server" do
        before do
          @api_client_with_key = {"name" => "lost-my-key", "private_key" => "the new private key"}
          @http_client.should_receive(:put).
            with("clients/lost-my-key", :name => "lost-my-key", :admin => false, :private_key => true).
            and_return(@api_client_with_key)
        end

        it "returns an ApiClient with a private key" do
          response = Chef::ApiClient.reregister("lost-my-key")
          # no sane == method for ApiClient :'(
          response.should == @api_client_without_key
          response.private_key.should == "the new private key"
          response.name.should == "lost-my-key"
          response.admin.should be_false
        end
      end

    end
  end
end


