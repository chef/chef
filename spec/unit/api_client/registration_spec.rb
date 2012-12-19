#
# Author:: Daniel DeLeo (<dan@opscode.com>)
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
require 'tempfile'

require 'chef/api_client/registration'

describe Chef::ApiClient::Registration do
  let(:key_location) do
    path = nil
    Tempfile.open("client-registration-key") {|f| path = f.path }
    File.unlink(path)
    path
  end

  let(:registration) { Chef::ApiClient::Registration.new("silent-bob", key_location) }

  let :private_key_data do
    File.open(Chef::Config[:validation_key], "r") {|f| f.read.chomp }
  end

  before do
    Chef::Config[:validation_client_name] = "test-validator"
    Chef::Config[:validation_key] = File.expand_path('ssl/private_key.pem', CHEF_SPEC_DATA)
  end

  after do
    File.unlink(key_location) if File.exist?(key_location)
    Chef::Config[:validation_client_name] = nil
    Chef::Config[:validation_key] = nil
  end

  it "has an HTTP client configured with validator credentials" do
    registration.http_api.should be_a_kind_of(Chef::REST)
    registration.http_api.client_name.should == "test-validator"
    registration.http_api.signing_key.should == private_key_data
  end

  describe "when creating/updating the client on the server" do
    let(:http_mock) { mock("Chef::REST mock") }

    before do
      registration.stub!(:http_api).and_return(http_mock)
    end

    it "creates a new ApiClient on the server using the validator identity" do
      response = {"uri" => "https://chef.local/clients/silent-bob", 
                  "private_key" => "--begin rsa key etc--"}
      http_mock.should_receive(:post).
        with("clients", :name => 'silent-bob', :admin => false).
        and_return(response)
      registration.create_or_update.should == response
      registration.private_key.should == "--begin rsa key etc--"
    end

    context "and the client already exists on a Chef 10 server" do
      it "requests a new key from the server and saves it" do
        response = {"name" => "silent-bob", "private_key" => "--begin rsa key etc--" }

        response_409 = Net::HTTPConflict.new("1.1", "409", "Conflict")
        exception_409 = Net::HTTPServerException.new("409 conflict", response_409)

        http_mock.should_receive(:post).and_raise(exception_409)
        http_mock.should_receive(:put).
          with("clients/silent-bob", :name => 'silent-bob', :admin => false, :private_key => true).
          and_return(response)
        registration.create_or_update.should == response
        registration.private_key.should == "--begin rsa key etc--"
      end
    end

    context "and the client already exists on a Chef 11 server" do
      it "requests a new key from the server and saves it" do
        response = Chef::ApiClient.new
        response.name("silent-bob")
        response.private_key("--begin rsa key etc--")

        response_409 = Net::HTTPConflict.new("1.1", "409", "Conflict")
        exception_409 = Net::HTTPServerException.new("409 conflict", response_409)

        http_mock.should_receive(:post).and_raise(exception_409)
        http_mock.should_receive(:put).
          with("clients/silent-bob", :name => 'silent-bob', :admin => false, :private_key => true).
          and_return(response)
        registration.create_or_update.should == response
        registration.private_key.should == "--begin rsa key etc--"
      end
    end
  end

  describe "when writing the private key to disk" do
    before do
      registration.stub!(:private_key).and_return('--begin rsa key etc--')
    end

    # Permission read via File.stat is busted on windows, though creating the
    # file with 0600 has the desired effect of giving access rights to the
    # owner only. A platform-specific functional test would be helpful.
    it "creates the file with 0600 permissions", :unix_only do
      File.should_not exist(key_location)
      registration.write_key
      File.should exist(key_location)
      stat = File.stat(key_location)
      (stat.mode & 07777).should == 0600
    end

    it "writes the private key content to the file" do
      registration.write_key
      IO.read(key_location).should == "--begin rsa key etc--"
    end
  end

  describe "when registering a client" do

    let(:http_mock) { mock("Chef::REST mock") }

    before do
      registration.stub!(:http_api).and_return(http_mock)
    end

    it "creates the client on the server and writes the key" do
      response = {"uri" => "http://chef.local/clients/silent-bob",
                  "private_key" => "--begin rsa key etc--" }
      http_mock.should_receive(:post).ordered.and_return(response)
      registration.run
      IO.read(key_location).should == "--begin rsa key etc--"
    end

    it "retries up to 5 times" do
      response_500 = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      exception_500 = Net::HTTPFatalError.new("500 Internal Server Error", response_500)

      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 1
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 2
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 3
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 4
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 5

      response = {"uri" => "http://chef.local/clients/silent-bob",
                  "private_key" => "--begin rsa key etc--" }
      http_mock.should_receive(:post).ordered.and_return(response)
      registration.run
      IO.read(key_location).should == "--begin rsa key etc--"
    end

    it "gives up retrying after the max attempts" do
      response_500 = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      exception_500 = Net::HTTPFatalError.new("500 Internal Server Error", response_500)

      http_mock.should_receive(:post).exactly(6).times.and_raise(exception_500)

      lambda {registration.run}.should raise_error(Net::HTTPFatalError)
    end

  end

end


