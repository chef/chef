#
# Author:: Steven Murawski (<smurawski@chef.io>)
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
require_relative "../../../lib/chef/knife/wsman_test"

describe Chef::Knife::WsmanTest do
  let(:http_client_mock) { HTTPClient.new }
  let(:ssl_policy) { double("DefaultSSLPolicy", set_custom_certs: nil) }

  before(:all) do
    Chef::Config.reset
  end

  before(:each) do
    response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 2.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
    http_response_mock = HTTP::Message.new_response(response_body)
    allow(http_client_mock).to receive(:post).and_return(http_response_mock)
    allow(HTTPClient).to receive(:new).and_return(http_client_mock)
    subject.config[:verbosity] = 0
    allow(subject.ui).to receive(:ask).and_return("prompted_password")
    allow(Chef::HTTP::DefaultSSLPolicy).to receive(:new)
      .with(http_client_mock.ssl_config)
      .and_return(ssl_policy)
    subject.merge_configs
  end

  subject { Chef::Knife::WsmanTest.new(["-m", "localhost"]) }

  it "sets the ssl policy" do
    expect(ssl_policy).to receive(:set_custom_certs).twice
    subject.run
  end

  context "when testing the WSMAN endpoint" do
    context "and the service responds" do
      context "successfully" do
        it "writes a message about a successful connection" do
          expect(subject.ui).to receive(:msg)
          subject.run
        end
      end

      context "with an invalid body" do
        it "warns for a failed connection and exit with a status of 1" do
          response_body = "I am invalid"
          http_response_mock = HTTP::Message.new_response(response_body)
          allow(http_client_mock).to receive(:post).and_return(http_response_mock)
          expect(subject.ui).to receive(:warn)
          expect(subject.ui).to receive(:error)
          expect(subject).to receive(:exit).with(1)
          subject.run
        end
      end

      context "with a non-200 code" do
        it "warns for a failed connection and exits with a status of 1" do
          http_response_mock = HTTP::Message.new_response("<resp></resp>")
          http_response_mock.status = 404
          allow(http_client_mock).to receive(:post).and_return(http_response_mock)
          expect(subject.ui).to receive(:warn)
          expect(subject.ui).to receive(:error)
          expect(subject).to receive(:exit).with(1)
          subject.run
        end
      end
    end

    context "and the service does not respond" do
      error_message = "A connection attempt failed because the connected party did not properly respond after a period of time."

      before(:each) do
        allow(http_client_mock).to receive(:post).and_raise(Exception.new(error_message))
      end

      it "exits with a status code of 1" do
        expect(subject).to receive(:exit).with(1)
        subject.run
      end

      it "writes a warning message for each node it fails to connect to" do
        expect(subject.ui).to receive(:warn)
        expect(subject).to receive(:exit).with(1)
        subject.run
      end

      it "writes an error message if it fails to connect to any nodes" do
        expect(subject.ui).to receive(:error)
        expect(subject).to receive(:exit).with(1)
        subject.run
      end
    end
  end

  context "when not validating ssl cert" do
    before(:each) do
      expect(subject.ui).to receive(:msg)
      subject.config[:winrm_ssl_verify_mode] = :verify_none
      subject.config[:winrm_transport] = :ssl
    end

    it "sets verify_mode to verify_none" do
      subject.run
      expect(http_client_mock.ssl_config.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)
    end
  end

  context "when testing the WSMAN endpoint with verbose output" do
    before(:each) do
      subject.config[:verbosity] = 1
    end

    context "and the service does not respond" do
      it "returns an object with an error message" do
        error_message = "A connection attempt failed because the connected party did not properly respond after a period of time."
        allow(http_client_mock).to receive(:post).and_raise(Exception.new(error_message))
        expect(subject).to receive(:exit).with(1)
        expect(subject).to receive(:output) do |output|
          expect(output.error_message).to  match(/#{error_message}/)
        end
        subject.run
      end
    end

    context "with an invalid body" do
      it "includes invalid body in error message" do
        response_body = "I am invalid"
        http_response_mock = HTTP::Message.new_response(response_body)
        allow(http_client_mock).to receive(:post).and_return(http_response_mock)
        expect(subject).to receive(:exit).with(1)
        expect(subject).to receive(:output) do |output|
          expect(output.error_message).to  match(/#{response_body}/)
        end
        subject.run
      end
    end

    context "and the target node is Windows Server 2008 R2" do
      before(:each) do
        ws2008r2_response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 2.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
        http_response_mock = HTTP::Message.new_response(ws2008r2_response_body)
        allow(http_client_mock).to receive(:post).and_return(http_response_mock)
      end

      it "identifies the stack of the product version as 2.0 " do
        expect(subject).to receive(:output) do |output|
          expect(output.product_version).to eq "OS: 0.0.0 SP: 0.0 Stack: 2.0"
        end
        subject.run
      end

      it "identifies the protocol version as the current DMTF standard" do
        expect(subject).to receive(:output) do |output|
          expect(output.protocol_version).to eq "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
        end
        subject.run
      end

      it "identifies the vendor as the Microsoft Corporation" do
        expect(subject).to receive(:output) do |output|
          expect(output.product_vendor).to  eq "Microsoft Corporation"
        end
        subject.run
      end
    end

    context "and the target node is Windows Server 2012 R2" do
      before(:each) do
        ws2012_response_body = '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"><s:Header/><s:Body><wsmid:IdentifyResponse xmlns:wsmid="http://schemas.dmtf.org/wbem/wsman/identity/1/wsmanidentity.xsd"><wsmid:ProtocolVersion>http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd</wsmid:ProtocolVersion><wsmid:ProductVendor>Microsoft Corporation</wsmid:ProductVendor><wsmid:ProductVersion>OS: 0.0.0 SP: 0.0 Stack: 3.0</wsmid:ProductVersion></wsmid:IdentifyResponse></s:Body></s:Envelope>'
        http_response_mock = HTTP::Message.new_response(ws2012_response_body)
        allow(http_client_mock).to receive(:post).and_return(http_response_mock)
      end

      it "identifies the stack of the product version as 3.0 " do
        expect(subject).to receive(:output) do |output|
          expect(output.product_version).to eq "OS: 0.0.0 SP: 0.0 Stack: 3.0"
        end
        subject.run
      end

      it "identifies the protocol version as the current DMTF standard" do
        expect(subject).to receive(:output) do |output|
          expect(output.protocol_version).to eq "http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd"
        end
        subject.run
      end

      it "identifies the vendor as the Microsoft Corporation" do
        expect(subject).to receive(:output) do |output|
          expect(output.product_vendor).to  eq "Microsoft Corporation"
        end
        subject.run
      end
    end
  end
end
