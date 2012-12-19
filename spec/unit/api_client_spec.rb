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

  it "has a name attribute" do
    @client.name("ops_master")
    @client.name.should == "ops_master"
  end

  it "does not allow spaces in the name" do
    lambda { @client.name "ops master" }.should raise_error(ArgumentError)
  end

  it "only allows string values for the name" do
    lambda { @client.name Hash.new }.should raise_error(ArgumentError)
  end

  it "has an admin flag attribute" do
    @client.admin(true)
    @client.admin.should be_true
  end

  it "defaults to non-admin" do
    @client.admin.should be_false
  end

  it "allows only boolean values for the admin flag" do
    lambda { @client.admin(false) }.should_not raise_error
    lambda { @client.admin(Hash.new) }.should raise_error(ArgumentError)
  end


  it "has a public key attribute" do
    @client.public_key("super public")
    @client.public_key.should == "super public"
  end

  it "accepts only String values for the public key" do
    lambda { @client.public_key "" }.should_not raise_error
    lambda { @client.public_key Hash.new }.should raise_error(ArgumentError)
  end


  it "has a private key attribute" do
    @client.private_key("super private")
    @client.private_key.should == "super private"
  end

  it "accepts only String values for the private key" do
    lambda { @client.private_key "" }.should_not raise_error
    lambda { @client.private_key Hash.new }.should raise_error(ArgumentError)
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
  end

  describe "when deserializing from JSON" do
    before(:each) do
      client = {
      "name" => "black",
      "public_key" => "crowes",
      "private_key" => "monkeypants",
      "admin" => true,
      "json_class" => "Chef::ApiClient"
      }
      @client = Chef::JSONCompat.from_json(client.to_json)
    end

    it "should deserialize to a Chef::ApiClient object" do
      @client.should be_a_kind_of(Chef::ApiClient)
    end

    it "preserves the name" do
      @client.name.should == "black"
    end

    it "preserves the public key" do
      @client.public_key.should == "crowes"
    end

    it "preserves the admin status" do
      @client.admin.should be_true
    end

    it "includes the private key if present" do
      @client.private_key.should == "monkeypants"
    end

  end

  describe "with correctly configured API credentials" do
    before do
      Chef::Config[:node_name] = "silent-bob"
      Chef::Config[:client_key] = File.expand_path('ssl/private_key.pem', CHEF_SPEC_DATA)
    end

    after do
      Chef::Config[:node_name] = nil
      Chef::Config[:client_key] = nil
    end

    let :private_key_data do
      File.open(Chef::Config[:client_key], "r") {|f| f.read.chomp }
    end

    it "has an HTTP client configured with default credentials" do
      @client.http_api.should be_a_kind_of(Chef::REST)
      @client.http_api.client_name.should == "silent-bob"
      @client.http_api.signing_key.to_s.should == private_key_data
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
        lambda { Chef::ApiClient.reregister("lost-my-key") }.should raise_error(Net::HTTPServerException)
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


