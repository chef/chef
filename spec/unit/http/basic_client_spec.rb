#
# Author:: Cameron Cope (<ccope@brightcove.com>)
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
require 'chef/http/basic_client'

describe "HTTP Connection" do

  let(:uri) { URI("https://example.com:4443") }
  subject(:basic_client) { Chef::HTTP::BasicClient.new(uri) }

  describe ".new" do
    it "creates an instance" do
      subject
    end
  end

  describe "#build_http_client" do
    it "should build an http client" do
      subject.build_http_client
    end

    it "should set an open timeout" do
      expect(subject.build_http_client.open_timeout).not_to be_nil
    end
  end

  describe "#http_client_builder" do
    subject(:http_client_builder) { basic_client.http_client_builder }

    context "when the http_proxy is an URI" do
      before :each do
        allow(basic_client).to receive(:proxy_uri).and_return(URI.parse(
          "http://user:pass@example.com:1234"
        ))
      end

      it "has a proxy_address" do
        expect(http_client_builder.proxy_address).to eq "example.com"
      end

      it "has a proxy_pass" do
        expect(http_client_builder.proxy_pass).to eq "pass"
      end

      it "has a proxy_port" do
        expect(http_client_builder.proxy_port).to eq 1234
      end

      it "has a proxy_user" do
        expect(http_client_builder.proxy_user).to eq "user"
      end
    end

    context "when the http_proxy is nil" do
      before :each do
        allow(basic_client).to receive(:proxy_uri).and_return(nil)
      end

      it "returns Net::HTTP" do
        expect(basic_client.http_client_builder).to eq Net::HTTP
      end
    end
  end

  describe "#proxy_uri" do
    subject(:proxy_uri) { basic_client.proxy_uri }

    shared_examples_for "a proxy uri" do
      let(:proxy_host) { "proxy.mycorp.com" }
      let(:proxy_port) { 8080 }
      let(:proxy) { "#{proxy_prefix}#{proxy_host}:#{proxy_port}" }

      it "should contain the host" do
        expect(proxy_uri.host).to eq(proxy_host)
      end

      it "should contain the port" do
        expect(proxy_uri.port).to eq(proxy_port)
      end
    end

    context "when the config setting is normalized (does not contain the scheme)" do
      include_examples "a proxy uri" do

        let(:proxy_prefix) { "" }

        before do
          Chef::Config["#{uri.scheme}_proxy"] = proxy
          Chef::Config[:no_proxy] = nil
        end

      end
    end

    context "when the config setting is not normalized (contains the scheme)" do
      include_examples "a proxy uri" do
        let(:proxy_prefix) { "#{uri.scheme}://" }

        before do
          Chef::Config["#{uri.scheme}_proxy"] = proxy
          Chef::Config[:no_proxy] = nil
        end

      end
    end

    context "when the proxy is set by the environment" do

      include_examples "a proxy uri" do

        let(:env) do
          {
            "https_proxy" => "https://proxy.mycorp.com:8080",
            "https_proxy_user" => "jane_username",
            "https_proxy_pass" => "opensesame"
          }
        end

        let(:proxy_uri) { URI.parse(env["https_proxy"]) }

        before do
          allow(basic_client).to receive(:env).and_return(env)
        end

        it "sets the proxy user" do
          expect(basic_client.http_proxy_user(proxy_uri)).to eq("jane_username")
        end

        it "sets the proxy pass" do
          expect(basic_client.http_proxy_pass(proxy_uri)).to eq("opensesame")
        end
      end

    end

    context "when an empty proxy is set by the environment" do
      let(:env) do
        {
          "https_proxy" => ""
        }
      end

      before do
        allow(subject).to receive(:env).and_return(env)
      end

      it "to not fail with URI parse exception" do
        expect { proxy_uri }.to_not raise_error
      end

      it "returns nil" do
        expect(proxy_uri).to eq nil
      end
    end
  end
end
