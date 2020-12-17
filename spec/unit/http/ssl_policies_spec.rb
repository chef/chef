#--
# Author:: Daniel DeLeo (<dan@chef.io>)
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
require "chef/http/ssl_policies"

describe "HTTP SSL Policy" do

  before do
    Chef::Config[:ssl_client_cert] = nil
    Chef::Config[:ssl_client_key]  = nil
    Chef::Config[:ssl_ca_path]     = nil
    Chef::Config[:ssl_ca_file]     = nil
    ENV["SSL_CERT_FILE"]           = nil
  end

  let(:http_client) do
    ssl_policy_class.apply_to(Net::HTTP.new("example.com"))
  end

  describe Chef::HTTP::DefaultSSLPolicy do

    let(:ssl_policy_class) { Chef::HTTP::DefaultSSLPolicy }

    it "raises a ConfigurationError if :ssl_ca_path is set to a path that doesn't exist" do
      Chef::Config[:ssl_ca_path] = "/dev/null/nothing_here"
      expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError)
    end

    it "should set the CA path if that is set in the configuration" do
      Chef::Config[:ssl_ca_path] = File.join(CHEF_SPEC_DATA, "ssl")
      expect(http_client.ca_path).to eq(File.join(CHEF_SPEC_DATA, "ssl"))
    end

    it "raises a ConfigurationError if :ssl_ca_file is set to a file that does not exist" do
      Chef::Config[:ssl_ca_file] = "/dev/null/nothing_here"
      expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError)
    end

    it "should set the CA file if that is set in the configuration" do
      Chef::Config[:ssl_ca_file] = CHEF_SPEC_DATA + "/ssl/5e707473.0"
      expect(http_client.ca_file).to eq(CHEF_SPEC_DATA + "/ssl/5e707473.0")
    end

    it "should set the custom CA file if SSL_CERT_FILE environment variable is set" do
      ENV["SSL_CERT_FILE"] = CHEF_SPEC_DATA + "/trusted_certs/intermediate.pem"
      expect(http_client.ca_file).to eq(CHEF_SPEC_DATA + "/trusted_certs/intermediate.pem")
    end

    it "raises a ConfigurationError if SSL_CERT_FILE environment variable is set to a file that does not exist" do
      ENV["SSL_CERT_FILE"] = "/dev/null/nothing_here"
      expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError)
    end

    it "sets the OpenSSL verify mode to verify_peer when configured with :ssl_verify_mode set to :verify_peer" do
      Chef::Config[:ssl_verify_mode] = :verify_peer
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
    end

    it "sets the OpenSSL verify mode to :verify_none when configured with :ssl_verify_mode set to :verify_none" do
      Chef::Config[:ssl_verify_mode] = :verify_none
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
    end

    describe "when configured with a client certificate" do
      it "raises ConfigurationError if the certificate file doesn't exist" do
        Chef::Config[:ssl_client_cert] = "/dev/null/nothing_here"
        Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + "/ssl/chef-rspec.key"
        expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError, /ssl_client_cert .* does not exist/)
      end

      it "raises ConfigurationError if the private key file doesn't exist" do
        Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + "/ssl/chef-rspec.cert"
        Chef::Config[:ssl_client_key]  = "/dev/null/nothing_here"
        expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError, /ssl_client_key .* does not exist/)
      end

      it "raises a ConfigurationError if one of :ssl_client_cert and :ssl_client_key is set but not both" do
        Chef::Config[:ssl_client_cert] = "/dev/null/nothing_here"
        Chef::Config[:ssl_client_key]  = nil
        expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError, /configure ssl_client_cert and ssl_client_key together/)
      end

      it "raises a ConfigurationError with a bad cert file" do
        Chef::Config[:ssl_client_cert] = __FILE__
        Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + "/ssl/chef-rspec.key"
        expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError, /Error reading cert file '#{__FILE__}'/)
      end

      it "raises a ConfigurationError with a bad key file" do
        Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + "/ssl/chef-rspec.cert"
        Chef::Config[:ssl_client_key]  = __FILE__
        expect { http_client }.to raise_error(Chef::Exceptions::ConfigurationError, /Error reading key file '#{__FILE__}'/)
      end

      it "configures the HTTP client's cert and private key" do
        Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + "/ssl/chef-rspec.cert"
        Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + "/ssl/chef-rspec.key"
        expect(http_client.cert.to_s).to eq(OpenSSL::X509::Certificate.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.cert")).to_s)
        expect(http_client.key.to_s).to eq(OpenSSL::PKey::RSA.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.key")).to_s)
      end

      it "configures the HTTP client's cert and private key with a DER encoded cert" do
        Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + "/ssl/binary/chef-rspec-der.cert"
        Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + "/ssl/chef-rspec.key"
        expect(http_client.cert.to_s).to eq(OpenSSL::X509::Certificate.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.cert")).to_s)
        expect(http_client.key.to_s).to eq(OpenSSL::PKey::RSA.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.key")).to_s)
      end

      it "configures the HTTP client's cert and private key with a DER encoded key" do
        Chef::Config[:ssl_client_cert] = CHEF_SPEC_DATA + "/ssl/chef-rspec.cert"
        Chef::Config[:ssl_client_key]  = CHEF_SPEC_DATA + "/ssl/binary/chef-rspec-der.key"
        expect(http_client.cert.to_s).to eq(OpenSSL::X509::Certificate.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.cert")).to_s)
        expect(http_client.key.to_s).to eq(OpenSSL::PKey::RSA.new(IO.read(CHEF_SPEC_DATA + "/ssl/chef-rspec.key")).to_s)
      end
    end

    context "when additional certs are located in the trusted_certs dir" do
      before do
        Chef::Config.trusted_certs_dir = File.join(CHEF_SPEC_DATA, "trusted_certs")
      end

      it "enables verification of self-signed certificates" do
        path = File.join(CHEF_SPEC_DATA, "trusted_certs", "example.crt")
        self_signed_crt = OpenSSL::X509::Certificate.new(File.binread(path))

        expect(http_client.cert_store.verify(self_signed_crt)).to be_truthy
      end

      it "enables verification of cert chains" do
        # This cert is signed by DigiCert so it would be valid in normal SSL usage.
        # The chain goes:
        # trusted root -> intermediate -> opscode.pem
        # In this test, the intermediate has to be loaded and trusted in order
        # for verification to work correctly.
        # If the machine running the test doesn't have ruby SSL configured correctly,
        # then the root cert also has to be loaded for the test to succeed.
        # The system under test **SHOULD** do both of these things.
        path = File.join(CHEF_SPEC_DATA, "trusted_certs", "opscode.pem")
        additional_pem = OpenSSL::X509::Certificate.new(File.binread(path))

        expect(http_client.cert_store.verify(additional_pem)).to be_truthy
      end

      it "skips duplicate certs" do
        # For whatever reason, OpenSSL errors out when adding a
        # cert you already have to the certificate store.
        ssl_policy = ssl_policy_class.new(Net::HTTP.new("example.com"))
        ssl_policy.set_custom_certs
        ssl_policy.set_custom_certs # should not raise an error
      end

      it "raises ConfigurationError with a bad cert file in the trusted_certs dir" do
        ssl_policy = ssl_policy_class.new(Net::HTTP.new("example.com"))

        Dir.mktmpdir do |dir|
          bad_cert_file = File.join(dir, "bad_cert_file.crt")
          File.write(bad_cert_file, File.read(__FILE__))

          Chef::Config.trusted_certs_dir = dir
          expect { ssl_policy.set_custom_certs }.to raise_error(Chef::Exceptions::ConfigurationError, /Error reading cert file/)
        end
      end

      it "works with binary certs" do
        Chef::Config.trusted_certs_dir = File.join(CHEF_SPEC_DATA, "ssl", "binary")

        ssl_policy = ssl_policy_class.new(Net::HTTP.new("example.com"))
        ssl_policy.set_custom_certs
      end
    end
  end

  describe Chef::HTTP::APISSLPolicy do

    let(:ssl_policy_class) { Chef::HTTP::APISSLPolicy }

    it "sets the OpenSSL verify mode to verify_peer when configured with :ssl_verify_mode set to :verify_peer" do
      Chef::Config[:ssl_verify_mode] = :verify_peer
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
    end

    it "sets the OpenSSL verify mode to :verify_none when configured with :ssl_verify_mode set to :verify_none" do
      Chef::Config[:ssl_verify_mode] = :verify_none
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
    end

    it "sets the OpenSSL verify mode to verify_peer when verify_api_cert is set" do
      Chef::Config[:verify_api_cert] = true
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
    end
  end

  describe Chef::HTTP::VerifyPeerSSLPolicy do

    let(:ssl_policy_class) { Chef::HTTP::VerifyPeerSSLPolicy }

    it "sets the OpenSSL verify mode to verify_peer" do
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_PEER)
    end

  end

  describe Chef::HTTP::VerifyNoneSSLPolicy do

    let(:ssl_policy_class) { Chef::HTTP::VerifyNoneSSLPolicy }

    it "sets the OpenSSL verify mode to verify_peer" do
      expect(http_client.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
    end

  end
end
