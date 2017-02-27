#
# Author:: Jay Mundrawala (<jdm@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
require "chef/mixin/uris"

class Chef::UrisTest
  include Chef::Mixin::Uris
end

describe Chef::Mixin::Uris do
  let (:uris) { Chef::UrisTest.new }

  describe "#uri_scheme?" do
    it "matches 'scheme://foo.com'" do
      expect(uris.uri_scheme?("scheme://foo.com")).to eq(true)
    end

    it "does not match 'c:/foo.com'" do
      expect(uris.uri_scheme?("c:/foo.com")).to eq(false)
    end

    it "does not match '/usr/bin/foo.com'" do
      expect(uris.uri_scheme?("/usr/bin/foo.com")).to eq(false)
    end

    it "does not match 'c:/foo.com://bar.com'" do
      expect(uris.uri_scheme?("c:/foo.com://bar.com")).to eq(false)
    end
  end

  describe "#as_uri" do
    it "parses a file scheme uri with spaces" do
      expect { uris.as_uri("file:///c:/foo bar.txt") }.not_to raise_exception
    end

    it "returns a URI object" do
      expect( uris.as_uri("file:///c:/foo bar.txt") ).to be_a(URI)
    end
  end

end
