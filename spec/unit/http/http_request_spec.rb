#
# Author:: Klaas Jan Wierenga (<k.j.wierenga@gmail.com>)
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

describe Chef::HTTP::HTTPRequest do

  context "with HTTP url scheme" do

    it "should not include port 80 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com"), "")

      expect(request.headers["Host"]).to eql("dummy.com")
    end

    it "should not include explicit port 80 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com:80"), "")

      expect(request.headers["Host"]).to eql("dummy.com")
    end

    it "should include explicit port 8000 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com:8000"), "")

      expect(request.headers["Host"]).to eql("dummy.com:8000")
    end

    it "should include explicit 443 port in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com:443"), "")

      expect(request.headers["Host"]).to eql("dummy.com:443")
    end

    it "should pass on explicit Host header unchanged" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com:8000"), "", { "Host" => "yourhost.com:8888" })

      expect(request.headers["Host"]).to eql("yourhost.com:8888")
    end

  end

  context "with HTTPS url scheme" do

    it "should not include port 443 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("https://dummy.com"), "")

      expect(request.headers["Host"]).to eql("dummy.com")
    end

    it "should include explicit port 80 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("https://dummy.com:80"), "")

      expect(request.headers["Host"]).to eql("dummy.com:80")
    end

    it "should include explicit port 8000 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("https://dummy.com:8000"), "")

      expect(request.headers["Host"]).to eql("dummy.com:8000")
    end

    it "should not include explicit port 443 in Host header" do
      request = Chef::HTTP::HTTPRequest.new(:GET, URI("https://dummy.com:443"), "")

      expect(request.headers["Host"]).to eql("dummy.com")
    end

  end

  it "should pass on explicit Host header unchanged" do
    request = Chef::HTTP::HTTPRequest.new(:GET, URI("http://dummy.com:8000"), "", { "Host" => "myhost.com:80" })

    expect(request.headers["Host"]).to eql("myhost.com:80")
  end

end
