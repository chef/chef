#
# Author:: Chris Doherty (cdoherty@chef.io>)
# Copyright:: Copyright 2016, Chef Software Inc.
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
require "net/http"
require "open-uri"

describe "proxy variables" do
  let(:yes_proxies) { %w{http_proxy https_proxy ftp_proxy} }
  let(:all_vars) { yes_proxies + ["no_proxy"] }

  BOGUS_PROXY = "http://127.0.0.1:225" # /etc/services says 225 is reserved.
  HTTP_URL  = "http://www.example.com"
  HTTPS_URL = "https://www.example.com"

  before(:each) {
    yes_proxies.each { |proxy| ENV[proxy] = BOGUS_PROXY }
  }

  after(:each) {
    all_vars.each do |proxy|
      ENV.delete(proxy)
    end
  }

  let(:gets) {
    {
      :chef_http => lambda { |url|
        uri = URI(url)
        path = uri.path.empty? ? "/" : uri.path
        Chef::Config[:rest_timeout] = 2
        client = Chef::HTTP.new(url)
        client.get(path)
      },
      :net_http => lambda { |url|
        uri = URI(url)
        ::Net::HTTP.new(uri.host, uri.port).start do |client|
          client.request(::Net::HTTP::Get.new(uri))
        end
      },
    }
  }

  context "no_proxy" do

    shared_examples "compatibility" do |library|
      it "fails when trying to reach a non-exempted domain" do
        ENV["no_proxy"] = "fizzgig.com"
        expect { gets[library].call(HTTP_URL) }.to raise_error(Errno::ECONNREFUSED)
      end

      %w{
        www.example.com
        example.com
        .example.com
        *.example.com
        }.each do |no_proxy_value|
        context "with no_proxy=#{no_proxy_value}" do
          it "reaches the exempted domain (#{HTTP_URL}) via HTTP" do
            ENV["no_proxy"] = no_proxy_value
            expect { gets[library].call(HTTP_URL) }.not_to raise_error
          end

          it "reaches the exempted domain (#{HTTPS_URL}) via HTTPS" do
            ENV["no_proxy"] = no_proxy_value
            expect { gets[library].call(HTTPS_URL) }.not_to raise_error
          end
        end
      end
    end

    context "Net::HTTP" do
      include_examples "compatibility", :net_http
    end

    context "Chef::HTTP" do
      include_examples "compatibility", :chef_http
    end
  end
end
