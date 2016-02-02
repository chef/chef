#--
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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
describe URI do

  describe "when a URI contains an IPv6 literal" do

    let(:ipv6_uri) do
      URI.parse("https://[2a00:1450:4009:809::1008]:8443")
    end

    it "returns the hostname without brackets" do
      expect(ipv6_uri.hostname).to eq("2a00:1450:4009:809::1008")
    end

  end

end
