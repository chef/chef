#
# Author:: Steven Murawski <smurawski@chef.io>
# Copyright:: Copyright (c) 2015-2020 Chef Software, Inc.
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
require_relative "../../../lib/chef/knife/winrm"
require_relative "../../support/dummy_winrm_connection"

describe Chef::Knife::WinrmSession do
  let(:winrm_connection) { Dummy::Connection.new }
  let(:options) { { transport: :plaintext } }

  before do
    allow(WinRM::Connection).to receive(:new).and_return(winrm_connection)
  end

  subject { Chef::Knife::WinrmSession.new(options) }

  describe "#initialize" do
    context "when a proxy is configured" do
      let(:proxy_uri) { "blah.com" }
      let(:ssl_policy) { double("DefaultSSLPolicy", set_custom_certs: nil) }

      before do
        Chef::Config[:http_proxy] = proxy_uri
      end

      it "sets the http_proxy to the configured proxy" do
        subject
        expect(ENV["HTTP_PROXY"]).to eq("http://#{proxy_uri}")
      end

      it "sets the ssl policy on the winrm client" do
        expect(Chef::HTTP::DefaultSSLPolicy).to receive(:new)
          .with(winrm_connection.transport.httpcli.ssl_config)
          .and_return(ssl_policy)
        expect(ssl_policy).to receive(:set_custom_certs)
        subject
      end

    end
  end

  describe "#relay_command" do
    it "run command and display commands output" do
      expect(winrm_connection).to receive(:shell)
      subject.relay_command("cmd.exe echo 'hi'")
    end

    it "exits with 401 if command execution raises a 401" do
      expect(winrm_connection).to receive(:shell).and_raise(WinRM::WinRMHTTPTransportError.new("", "401"))
      expect { subject.relay_command("cmd.exe echo 'hi'") }.to raise_error(WinRM::WinRMHTTPTransportError)
      expect(subject.exit_code).to eql(401)
    end

    context "cmd shell" do
      before do
        options[:shell] = :cmd
        options[:codepage] = 65001
      end

      it "creates shell and sends codepage" do
        expect(winrm_connection).to receive(:shell).with(:cmd, hash_including(codepage: 65001))
        subject.relay_command("cmd.exe echo 'hi'")
      end
    end

    context "powershell shell" do
      before do
        options[:shell] = :powershell
        options[:codepage] = 65001
      end

      it "does not send codepage to shell" do
        expect(winrm_connection).to receive(:shell).with(:powershell)
        subject.relay_command("cmd.exe echo 'hi'")
      end
    end
  end
end
