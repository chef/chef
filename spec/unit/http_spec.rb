#
# Author:: Xabier de Zuazo (xabier@onddo.com)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
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

require 'chef/http'
require 'chef/http/basic_client'
require 'chef/http/socketless_chef_zero_client'

class Chef::HTTP
  public :create_url
end

describe Chef::HTTP do

  context "when given a chefzero:// URL" do

    let(:uri) { URI("chefzero://localhost:1") }

    subject(:http) { Chef::HTTP.new(uri) }

    it "uses the SocketlessChefZeroClient to handle requests" do
      expect(http.http_client).to be_a_kind_of(Chef::HTTP::SocketlessChefZeroClient)
      expect(http.http_client.url).to eq(uri)
    end

  end

  describe "create_url" do

    it 'should return a correctly formatted url 1/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com')
      expect(http.create_url('api/endpoint')).to eql(URI.parse('http://www.getchef.com/api/endpoint'))
    end

    it 'should return a correctly formatted url 2/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com/')
      expect(http.create_url('/organization/org/api/endpoint/')).to eql(URI.parse('http://www.getchef.com/organization/org/api/endpoint/'))
    end

    it 'should return a correctly formatted url 3/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com/organization/org///')
      expect(http.create_url('///api/endpoint?url=http://foo.bar')).to eql(URI.parse('http://www.getchef.com/organization/org/api/endpoint?url=http://foo.bar'))
    end

    # As per: https://github.com/opscode/chef/issues/2500
    it 'should treat scheme part of the URI in a case-insensitive manner' do
      http = Chef::HTTP.allocate # Calling Chef::HTTP::new sets @url, don't want that.
      expect { http.create_url('HTTP://www1.chef.io/') }.not_to raise_error
      expect(http.create_url('HTTP://www2.chef.io/')).to eql(URI.parse('http://www2.chef.io/'))
    end

  end # create_url

  describe "head" do

    it 'should return nil for a "200 Success" response (CHEF-4762)' do
      resp = Net::HTTPOK.new("1.1", 200, "OK")
      expect(resp).to receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      expect_any_instance_of(Chef::HTTP::BasicClient).to receive(:request).and_return(["request", resp])

      expect(http.head("http://www.getchef.com/")).to eql(nil)
    end

    it 'should return false for a "304 Not Modified" response (CHEF-4762)' do
      resp = Net::HTTPNotModified.new("1.1", 304, "Not Modified")
      expect(resp).to receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      expect_any_instance_of(Chef::HTTP::BasicClient).to receive(:request).and_return(["request", resp])

      expect(http.head("http://www.getchef.com/")).to eql(false)
    end

  end # head

end
