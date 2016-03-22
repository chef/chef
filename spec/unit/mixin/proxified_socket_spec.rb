#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "chef/mixin/proxified_socket"
require "proxifier/proxy"

class TestProxifiedSocket
  include Chef::Mixin::ProxifiedSocket
end

describe Chef::Mixin::ProxifiedSocket do

  before(:all) do
    @original_env = ENV.to_hash
  end

  after(:all) do
    ENV.clear
    ENV.update(@original_env)
  end

  let(:host) { "host" }
  let(:port) { 7979 }
  let(:test_instance) { TestProxifiedSocket.new }
  let(:socket_double) { instance_double(TCPSocket) }
  let(:proxifier_double) { instance_double(Proxifier::Proxy) }
  let(:http_uri) { "http://somehost:1" }
  let(:https_uri) { "https://somehost:1" }
  let(:no_proxy_spec) { nil }

  shared_examples "proxified socket" do
    it "wraps the Socket in a Proxifier::Proxy" do
      expect(Proxifier).to receive(:Proxy).with(proxy_uri).and_return(proxifier_double)
      expect(proxifier_double).to receive(:open).with(host, port).and_return(socket_double)
      expect(test_instance.proxified_socket(host, port)).to eq(socket_double)
    end
  end

  context "when no proxy is set" do
    it "returns a plain TCPSocket" do
      ENV["http_proxy"] = nil
      ENV["https_proxy"] = nil
      expect(TCPSocket).to receive(:new).with(host, port).and_return(socket_double)
      expect(test_instance.proxified_socket(host, port)).to eq(socket_double)
    end
  end

  context "when https_proxy is set" do
    before do
      # I'm purposefully setting both of these because we prefer the https
      # variable
      ENV["https_proxy"] = https_uri
      ENV["http_proxy"] = http_uri
    end

    let(:proxy_uri) { https_uri }
    include_examples "proxified socket"

    context "when no_proxy is set" do
      # This is testing that no_proxy is also provided to Proxified
      # when it is set
      before do
        ENV["no_proxy"] = no_proxy_spec
      end

      let(:no_proxy_spec) { "somehost1,somehost2" }
      include_examples "proxified socket"
    end
  end

  context "when http_proxy is set" do
    before do
      ENV["https_proxy"] = nil
      ENV["http_proxy"] = http_uri
    end

    let(:proxy_uri) { http_uri }
    include_examples "proxified socket"
  end

end
