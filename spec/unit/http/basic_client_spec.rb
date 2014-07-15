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
  subject { Chef::HTTP::BasicClient.new(uri) }

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
      subject.build_http_client.open_timeout.should_not be_nil
    end
  end

  describe "#proxy_uri" do
    shared_examples_for "a proxy uri" do
      let(:proxy_host) { "proxy.mycorp.com" }
      let(:proxy_port) { 8080 }
      let(:proxy) { "#{proxy_prefix}#{proxy_host}:#{proxy_port}" }

      before do
        Chef::Config["#{uri.scheme}_proxy"] = proxy
        Chef::Config[:no_proxy] = nil
      end

      it "should contain the host" do
        proxy_uri = subject.proxy_uri
        proxy_uri.host.should == proxy_host
      end

      it "should contain the port" do
        proxy_uri = subject.proxy_uri
        proxy_uri.port.should == proxy_port
      end
    end

    context "when the config setting is normalized (does not contain the scheme)" do
      include_examples "a proxy uri" do
        let(:proxy_prefix) { "" }
      end
    end

    context "when the config setting is not normalized (contains the scheme)" do
      include_examples "a proxy uri" do
        let(:proxy_prefix) { "#{uri.scheme}://" }
      end
    end
  end
end
