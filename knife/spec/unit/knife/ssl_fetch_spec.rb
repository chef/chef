#
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

require "knife_spec_helper"
require "chef/knife/ssl_fetch"

describe Chef::Knife::SslFetch do

  let(:name_args) { [] }
  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stderr
    stderr_io.string
  end

  def stdout
    stdout_io.string
  end

  subject(:ssl_fetch) do
    s = Chef::Knife::SslFetch.new
    s.name_args = name_args
    allow(s.ui).to receive(:stdout).and_return(stdout_io)
    allow(s.ui).to receive(:stderr).and_return(stderr_io)
    s
  end

  context "when no arguments are given" do

    before do
      Chef::Config.chef_server_url = "https://example.com:8443/chef-server"
    end

    it "uses the chef_server_url as the host to fetch" do
      expect(ssl_fetch.host).to eq("example.com")
      expect(ssl_fetch.port).to eq(8443)
    end
  end

  context "when a specific URI is given" do
    let(:name_args) { %w{https://example.test:10443/foo} }

    it "fetches the SSL configuration against the given host" do
      expect(ssl_fetch.host).to eq("example.test")
      expect(ssl_fetch.port).to eq(10443)
    end
  end

  context "when an invalid URI is given" do

    let(:name_args) { %w{foo.test} }

    it "prints an error and exits" do
      expect { ssl_fetch.run }.to raise_error(SystemExit)
      expected_stdout = <<~E
        USAGE: knife ssl fetch [URL] (options)
      E
      expected_stderr = <<~E
        ERROR: Given URI: `foo.test' is invalid
      E
      expect(stdout_io.string).to eq(expected_stdout)
      expect(stderr_io.string).to eq(expected_stderr)
    end

    context "and its malformed enough to make URI.parse barf" do

      let(:name_args) { %w{ftp://lkj\\blah:example.com/blah} }

      it "prints an error and exits" do
        expect { ssl_fetch.run }.to raise_error(SystemExit)
        expected_stdout = <<~E
          USAGE: knife ssl fetch [URL] (options)
        E
        expected_stderr = <<~E
          ERROR: Given URI: `#{name_args[0]}' is invalid
        E
        expect(stdout_io.string).to eq(expected_stdout)
        expect(stderr_io.string).to eq(expected_stderr)
      end
    end
  end

  describe "normalizing CNs for use as paths" do

    it "normalizes '*' to 'wildcard'" do
      expect(ssl_fetch.normalize_cn("*.example.com")).to eq("wildcard_example_com")
    end

    it "normalizes non-alnum and hyphen characters to underscores" do
      expect(ssl_fetch.normalize_cn("Billy-Bob's Super Awesome CA!")).to eq("Billy-Bob_s_Super_Awesome_CA_")
    end

  end

  describe "#cn_of" do
    let(:certificate) { double("Certificate", subject: subject) }

    describe "when the certificate has a common name" do
      let(:subject) { [["CN", "common name"]] }
      it "returns the common name" do
        expect(ssl_fetch.cn_of(certificate)).to eq("common name")
      end
    end

    describe "when the certificate does not have a common name" do
      let(:subject) { [] }
      it "returns nil" do
        expect(ssl_fetch.cn_of(certificate)).to eq(nil)
      end
    end
  end

  describe "fetching the remote cert chain" do

    let(:name_args) { %w{https://foo.example.com:8443} }

    let(:tcp_socket) { double(TCPSocket) }
    let(:ssl_socket) { double(OpenSSL::SSL::SSLSocket) }

    let(:self_signed_crt_path) { File.join(CHEF_SPEC_DATA, "trusted_certs", "example.crt") }
    let(:self_signed_crt) { OpenSSL::X509::Certificate.new(File.read(self_signed_crt_path)) }

    let(:trusted_certs_dir) { Dir.mktmpdir }

    def run
      ssl_fetch.run
    rescue Exception
      puts "OUT: #{stdout_io.string}"
      puts "ERR: #{stderr_io.string}"
      raise
    end

    before do
      Chef::Config.trusted_certs_dir = trusted_certs_dir
    end

    after do
      FileUtils.rm_rf(trusted_certs_dir)
    end

    context "when the TLS connection is successful" do

      before do
        expect(ssl_fetch).to receive(:proxified_socket).with("foo.example.com", 8443).and_return(tcp_socket)
        expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcp_socket, ssl_fetch.noverify_peer_ssl_context).and_return(ssl_socket)
        expect(ssl_socket).to receive(:connect)
        expect(ssl_socket).to receive(:peer_cert_chain).and_return([self_signed_crt])
      end

      it "fetches the cert chain and writes the certs to the trusted_certs_dir" do
        run
        stored_cert_path = File.join(trusted_certs_dir, "example_local.crt")
        expect(File).to exist(stored_cert_path)
        expect(File.read(stored_cert_path)).to eq(File.read(self_signed_crt_path))
      end

    end

    context "when connecting to a non-SSL service (like HTTP)" do

      let(:name_args) { %w{http://foo.example.com} }

      let(:unknown_protocol_error) { OpenSSL::SSL::SSLError.new("SSL_connect returned=1 errno=0 state=SSLv2/v3 read server hello A: unknown protocol") }

      before do
        expect(ssl_fetch).to receive(:proxified_socket).with("foo.example.com", 80).and_return(tcp_socket)
        expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcp_socket, ssl_fetch.noverify_peer_ssl_context).and_return(ssl_socket)
        expect(ssl_socket).to receive(:connect).and_raise(unknown_protocol_error)

        expect(ssl_fetch).to receive(:exit).with(1)
      end

      it "tells the user their URL is for a non-ssl service" do
        expected_error_text = <<~ERROR_TEXT
          ERROR: The service at the given URI (http://foo.example.com) does not accept SSL connections
          ERROR: Perhaps you meant to connect to 'https://foo.example.com'?
        ERROR_TEXT

        run
        expect(stderr).to include(expected_error_text)
      end

    end

    describe "when the certificate does not have a CN" do
      let(:self_signed_crt_path) { File.join(CHEF_SPEC_DATA, "trusted_certs", "example_no_cn.crt") }
      let(:self_signed_crt) { OpenSSL::X509::Certificate.new(File.read(self_signed_crt_path)) }

      before do
        expect(ssl_fetch).to receive(:proxified_socket).with("foo.example.com", 8443).and_return(tcp_socket)
        expect(OpenSSL::SSL::SSLSocket).to receive(:new).with(tcp_socket, ssl_fetch.noverify_peer_ssl_context).and_return(ssl_socket)
        expect(ssl_socket).to receive(:connect)
        expect(ssl_socket).to receive(:peer_cert_chain).and_return([self_signed_crt])
        expect(Time).to receive(:new).and_return(1)
      end

      it "fetches the certificate and writes it to a file in the trusted_certs_dir" do
        run
        stored_cert_path = File.join(trusted_certs_dir, "foo.example.com_1.crt")
        expect(File).to exist(stored_cert_path)
        expect(File.read(stored_cert_path)).to eq(File.read(self_signed_crt_path))
      end
    end

  end
end
