#
# Author:: Klaas Jan Wierenga (<k.j.wierenga@gmail.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::HTTP::HTTPRequest do

  it "should not include port in Host header when not specified in the URL" do
    request = Chef::HTTP::HTTPRequest.new(:GET, URI('http://dummy.com'), '')

    request.headers['Host'].should eql('dummy.com')
  end

  it "should not include port in Host header when explicitly set to 80 in the URL" do
    request = Chef::HTTP::HTTPRequest.new(:GET, URI('http://dummy.com:80'), '')

    request.headers['Host'].should eql('dummy.com')
  end

  it "should pass on port 8000 in Host header when set to 8000 in the URL" do
    request = Chef::HTTP::HTTPRequest.new(:GET, URI('http://dummy.com:8000'), '')

    request.headers['Host'].should eql('dummy.com:8000')
  end

end
