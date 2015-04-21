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

  describe "#proxy_uri" do
    shared_examples_for "a proxy uri" do
      let(:proxy_host) { "proxy.mycorp.com" }
      let(:proxy_port) { 8080 }
      let(:proxy) { "#{proxy_prefix}#{proxy_host}:#{proxy_port}" }

      it "should contain the host" do
        proxy_uri = subject.proxy_uri
        expect(proxy_uri.host).to eq(proxy_host)
      end

      it "should contain the port" do
        proxy_uri = subject.proxy_uri
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
  end
end
