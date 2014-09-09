#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
require 'stringio'

describe Chef::Knife::SslCheck do

  let(:name_args) { [] }
  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stderr
    stderr_io.string
  end

  def stdout
    stdout_io.string
  end

  subject(:ssl_check) do
    s = Chef::Knife::SslCheck.new
    s.ui.stub(:stdout).and_return(stdout_io)
    s.ui.stub(:stderr).and_return(stderr_io)
    s.name_args = name_args
    s
  end

  before do
    Chef::Config.chef_server_url = "https://example.com:8443/chef-server"
  end

  context "when no arguments are given" do
    it "uses the chef_server_url as the host to check" do
      expect(ssl_check.host).to eq("example.com")
      expect(ssl_check.port).to eq(8443)
    end
  end

  context "when a specific URI is given" do
    let(:name_args) { %w{https://example.test:10443/foo} }

    it "checks the SSL configuration against the given host" do
      expect(ssl_check.host).to eq("example.test")
      expect(ssl_check.port).to eq(10443)
    end
  end

  context "when an invalid URI is given" do

    let(:name_args) { %w{foo.test} }

    it "prints an error and exits" do
      expect { ssl_check.run }.to raise_error(SystemExit)
      expected_stdout=<<-E
USAGE: knife ssl check [URL] (options)
E
      expected_stderr=<<-E
ERROR: Given URI: `foo.test' is invalid
E
      expect(stdout_io.string).to eq(expected_stdout)
      expect(stderr_io.string).to eq(expected_stderr)
    end

    context "and its malformed enough to make URI.parse barf" do

      let(:name_args) { %w{ftp://lkj\\blah:example.com/blah} }

      it "prints an error and exits" do
        expect { ssl_check.run }.to raise_error(SystemExit)
        expected_stdout=<<-E
USAGE: knife ssl check [URL] (options)
E
        expected_stderr=<<-E
ERROR: Given URI: `#{name_args[0]}' is invalid
E
        expect(stdout_io.string).to eq(expected_stdout)
        expect(stderr_io.string).to eq(expected_stderr)
      end
    end
  end

  describe "verifying trusted certificate X509 properties" do
    let(:name_args) { %w{https://foo.example.com:8443} }

    let(:trusted_certs_dir) { File.join(CHEF_SPEC_DATA, "trusted_certs") }
    let(:trusted_cert_file) { File.join(trusted_certs_dir, "example.crt") }

    let(:store) { OpenSSL::X509::Store.new }
    let(:certificate) { OpenSSL::X509::Certificate.new(IO.read(trusted_cert_file)) }

    before do
      Chef::Config[:trusted_certs_dir] = trusted_certs_dir
      ssl_check.stub(:trusted_certificates).and_return([trusted_cert_file])
      store.stub(:add_cert).with(certificate)
      OpenSSL::X509::Store.stub(:new).and_return(store)
      OpenSSL::X509::Certificate.stub(:new).with(IO.read(trusted_cert_file)).and_return(certificate)
      ssl_check.stub(:verify_cert).and_return(true)
      ssl_check.stub(:verify_cert_host).and_return(true)
    end

    context "when the trusted certificates have valid X509 properties" do
      before do
        store.stub(:verify).with(certificate).and_return(true)
      end

      it "does not generate any X509 warnings" do
        expect(ssl_check.ui).not_to receive(:warn).with(/There are invalid certificates in your trusted_certs_dir/)
        ssl_check.run
      end
    end

    context "when the trusted certificates have invalid X509 properties" do
      before do
        store.stub(:verify).with(certificate).and_return(false)
        store.stub(:error_string).and_return("unable to get local issuer certificate")
      end

      it "generates a warning message with invalid certificate file names" do
        expect(ssl_check.ui).to receive(:warn).with(/#{trusted_cert_file}: unable to get local issuer certificate/)
        ssl_check.run
      end
    end
  end

  describe "verifying the remote certificate" do
    let(:name_args) { %w{https://foo.example.com:8443} }

    let(:tcp_socket) { double(TCPSocket) }
    let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket) }

    before do
      TCPSocket.should_receive(:new).with("foo.example.com", 8443).and_return(tcp_socket)
      OpenSSL::SSL::SSLSocket.should_receive(:new).with(tcp_socket, ssl_check.verify_peer_ssl_context).and_return(ssl_socket)
    end

    def run
      ssl_check.run
    rescue Exception
      #puts "OUT: #{stdout_io.string}"
      #puts "ERR: #{stderr_io.string}"
      raise
    end

    context "when the remote host's certificate is valid" do

      before do
        ssl_check.should_receive(:verify_X509).and_return(true) # X509 valid certs (no warn)
        ssl_socket.should_receive(:connect) # no error
        ssl_socket.should_receive(:post_connection_check).with("foo.example.com") # no error
      end

      it "prints a success message" do
        ssl_check.run
        expect(stdout_io.string).to include("Successfully verified certificates from `foo.example.com'")
      end
    end

    describe "and the certificate is not valid" do

      let(:tcp_socket_for_debug) { double(TCPSocket) }
      let(:ssl_socket_for_debug) { double(OpenSSL::SSL::SSLSocket) }

      let(:self_signed_crt_path) { File.join(CHEF_SPEC_DATA, "trusted_certs", "example.crt") }
      let(:self_signed_crt) { OpenSSL::X509::Certificate.new(File.read(self_signed_crt_path)) }

      before do
        trap(:INT, "DEFAULT")

        TCPSocket.should_receive(:new).
          with("foo.example.com", 8443).
          and_return(tcp_socket_for_debug)
        OpenSSL::SSL::SSLSocket.should_receive(:new).
          with(tcp_socket_for_debug, ssl_check.noverify_peer_ssl_context).
          and_return(ssl_socket_for_debug)
      end

      context "when the certificate's CN does not match the hostname" do
        before do
          ssl_check.should_receive(:verify_X509).and_return(true) # X509 valid certs
          ssl_socket.should_receive(:connect) # no error
          ssl_socket.should_receive(:post_connection_check).
            with("foo.example.com").
            and_raise(OpenSSL::SSL::SSLError)
          ssl_socket_for_debug.should_receive(:connect)
          ssl_socket_for_debug.should_receive(:peer_cert).and_return(self_signed_crt)
        end

        it "shows the CN used by the certificate and prints an error" do
          expect { run }.to raise_error(SystemExit)
          expect(stderr).to include("The SSL cert is signed by a trusted authority but is not valid for the given hostname")
          expect(stderr).to include("You are attempting to connect to:   'foo.example.com'")
          expect(stderr).to include("The server's certificate belongs to 'example.local'")
        end

      end

      context "when the cert is not signed by any trusted authority" do
        before do
          ssl_check.should_receive(:verify_X509).and_return(true) # X509 valid certs
          ssl_socket.should_receive(:connect).
            and_raise(OpenSSL::SSL::SSLError)
          ssl_socket_for_debug.should_receive(:connect)
          ssl_socket_for_debug.should_receive(:peer_cert).and_return(self_signed_crt)
        end

        it "shows the CN used by the certificate and prints an error" do
          expect { run }.to raise_error(SystemExit)
          expect(stderr).to include("The SSL certificate of foo.example.com could not be verified")
        end

      end
    end

  end

end
