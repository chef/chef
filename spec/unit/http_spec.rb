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

class Chef::HTTP
  public :create_url
end

describe Chef::HTTP do

  describe "create_url" do

    it 'should return a correctly formatted url 1/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com')
      http.create_url('api/endpoint').should eql(URI.parse('http://www.getchef.com/api/endpoint'))
    end

    it 'should return a correctly formatted url 2/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com/')
      http.create_url('/organization/org/api/endpoint/').should eql(URI.parse('http://www.getchef.com/organization/org/api/endpoint/'))
    end

    it 'should return a correctly formatted url 3/3 CHEF-5261' do
      http = Chef::HTTP.new('http://www.getchef.com/organization/org///')
      http.create_url('///api/endpoint?url=http://foo.bar').should eql(URI.parse('http://www.getchef.com/organization/org/api/endpoint?url=http://foo.bar'))
    end

  end # create_url

  describe "head" do

    it 'should return nil for a "200 Success" response (CHEF-4762)' do
      resp = Net::HTTPOK.new("1.1", 200, "OK")
      resp.should_receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      Chef::HTTP::BasicClient.any_instance.should_receive(:request).and_return(["request", resp])

      http.head("http://www.getchef.com/").should eql(nil)
    end

    it 'should return false for a "304 Not Modified" response (CHEF-4762)' do
      resp = Net::HTTPNotModified.new("1.1", 304, "Not Modified")
      resp.should_receive(:read_body).and_return(nil)
      http = Chef::HTTP.new("")
      Chef::HTTP::BasicClient.any_instance.should_receive(:request).and_return(["request", resp])

      http.head("http://www.getchef.com/").should eql(false)
    end

  end # head

end
