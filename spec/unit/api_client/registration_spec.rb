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
    make_tmpname("client-registration-key")
  end

  let(:client_name) { "silent-bob" }

  subject(:registration) { Chef::ApiClient::Registration.new(client_name, key_location) }

  let(:private_key_data) do
    File.open(Chef::Config[:validation_key], "r") {|f| f.read.chomp }
  end

  let(:http_mock) { double("Chef::REST mock") }

  let(:expected_post_data) do
    { :name => client_name, :admin => false, :public_key => generated_public_key.to_pem }
  end

  let(:expected_put_data) do
    { :name => client_name, :admin => false, :public_key => generated_public_key.to_pem }
  end

  let(:server_v10_response) do
    {"uri" => "https://chef.local/clients/#{client_name}",
     "private_key" => "--begin rsa key etc--"}
  end

  # Server v11 includes `json_class` on all replies
  let(:server_v11_response) do
    response = Chef::ApiClient.new
    response.name(client_name)
    response.private_key("--begin rsa key etc--")
    response
  end

  let(:response_409) { Net::HTTPConflict.new("1.1", "409", "Conflict") }
  let(:exception_409) { Net::HTTPServerException.new("409 conflict", response_409) }

  let(:generated_private_key_pem) { IO.read(File.expand_path('ssl/private_key.pem', CHEF_SPEC_DATA)) }
  let(:generated_private_key) { OpenSSL::PKey::RSA.new(generated_private_key_pem) }
  let(:generated_public_key) { generated_private_key.public_key }


  let(:create_with_pkey_response) do
    {
      "uri" => "",
      "public_key" => generated_public_key.to_pem
    }
  end

  let(:update_with_pkey_response) do
    {"name"=>client_name,
     "admin"=>false,
     "public_key"=> generated_public_key,
     "validator"=>false,
     "private_key"=>false,
     "clientname"=>client_name}
  end

  before do
    Chef::Config[:validation_client_name] = "test-validator"
    Chef::Config[:validation_key] = File.expand_path('ssl/private_key.pem', CHEF_SPEC_DATA)
    OpenSSL::PKey::RSA.stub(:generate).with(2048).and_return(generated_private_key)
  end

  after do
    File.unlink(key_location) if File.exist?(key_location)
  end

  it "has an HTTP client configured with validator credentials" do
    registration.http_api.should be_a_kind_of(Chef::REST)
    registration.http_api.client_name.should == "test-validator"
    registration.http_api.signing_key.should == private_key_data
  end

  describe "when creating/updating the client on the server" do
    before do
      registration.stub(:http_api).and_return(http_mock)
    end

    it "posts a locally generated public key to the server to create a client" do
      http_mock.should_receive(:post).
        with("clients", expected_post_data).
        and_return(create_with_pkey_response)
      registration.create_or_update.should == create_with_pkey_response
      registration.private_key.should == generated_private_key_pem
    end

    it "puts a locally generated public key to the server to update a client" do
      http_mock.should_receive(:post).
        with("clients", expected_post_data).
        and_raise(exception_409)
      http_mock.should_receive(:put).
        with("clients/#{client_name}", expected_put_data).
        and_return(update_with_pkey_response)
      registration.create_or_update.should == update_with_pkey_response
      registration.private_key.should == generated_private_key_pem
    end

    it "writes the generated private key to disk" do
      http_mock.should_receive(:post).
        with("clients", expected_post_data).
        and_return(create_with_pkey_response)
      registration.run
      IO.read(key_location).should == generated_private_key_pem
    end

    context "and the client already exists on a Chef 11 server" do
      it "requests a new key from the server and saves it" do
        http_mock.should_receive(:post).and_raise(exception_409)
        http_mock.should_receive(:put).
          with("clients/#{client_name}", expected_put_data).
          and_return(update_with_pkey_response)
        registration.create_or_update.should == update_with_pkey_response
        registration.private_key.should == generated_private_key_pem
      end
    end

    context "when local key generation is disabled" do

      let(:expected_post_data) do
        { :name => client_name, :admin => false }
      end

      let(:expected_put_data) do
        { :name => client_name, :admin => false, :private_key => true }
      end

      before do
        Chef::Config[:local_key_generation] = false
        OpenSSL::PKey::RSA.should_not_receive(:generate)
      end

      it "creates a new ApiClient on the server using the validator identity" do
        http_mock.should_receive(:post).
          with("clients", expected_post_data).
          and_return(server_v10_response)
        registration.create_or_update.should == server_v10_response
        registration.private_key.should == "--begin rsa key etc--"
      end

      context "and the client already exists on a Chef 11 server" do
        it "requests a new key from the server and saves it" do
          http_mock.should_receive(:post).and_raise(exception_409)
          http_mock.should_receive(:put).
            with("clients/#{client_name}", expected_put_data).
            and_return(server_v11_response)
          registration.create_or_update.should == server_v11_response
          registration.private_key.should == "--begin rsa key etc--"
        end
      end

      context "and the client already exists on a Chef 10 server" do
        it "requests a new key from the server and saves it" do
          http_mock.should_receive(:post).with("clients", expected_post_data).
            and_raise(exception_409)
          http_mock.should_receive(:put).
            with("clients/#{client_name}", expected_put_data).
            and_return(server_v10_response)
          registration.create_or_update.should == server_v10_response
          registration.private_key.should == "--begin rsa key etc--"
        end
      end
    end
  end

  describe "when writing the private key to disk" do
    before do
      registration.stub(:private_key).and_return('--begin rsa key etc--')
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

    context 'when the client key location is a symlink' do
      it 'does not follow the symlink', :unix_only do
        expected_flags = (File::CREAT|File::TRUNC|File::RDWR)

        if defined?(File::NOFOLLOW)
          expected_flags |= File::NOFOLLOW
        end

        expect(registration.file_flags).to eq(expected_flags)
      end

      context 'with follow_client_key_symlink set to true' do
        before do
          Chef::Config[:follow_client_key_symlink] = true
        end

        it 'follows the symlink', :unix_only do
          expect(registration.file_flags).to eq(File::CREAT|File::TRUNC|File::RDWR)
        end
      end
    end
  end

  describe "when registering a client" do

    before do
      registration.stub(:http_api).and_return(http_mock)
    end

    it "creates the client on the server and writes the key" do
      http_mock.should_receive(:post).ordered.and_return(server_v10_response)
      registration.run
      IO.read(key_location).should == generated_private_key_pem
    end

    it "retries up to 5 times" do
      response_500 = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      exception_500 = Net::HTTPFatalError.new("500 Internal Server Error", response_500)

      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 1
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 2
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 3
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 4
      http_mock.should_receive(:post).ordered.and_raise(exception_500) # 5

      http_mock.should_receive(:post).ordered.and_return(server_v10_response)
      registration.run
      IO.read(key_location).should == generated_private_key_pem
    end

    it "gives up retrying after the max attempts" do
      response_500 = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      exception_500 = Net::HTTPFatalError.new("500 Internal Server Error", response_500)

      http_mock.should_receive(:post).exactly(6).times.and_raise(exception_500)

      lambda {registration.run}.should raise_error(Net::HTTPFatalError)
    end

  end

end
