
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
require "chef/org"

describe Chef::Org do
  let(:org) { Chef::Org.new("myorg") }

  describe "API Interactions" do
    before(:each) do
      Chef::Config[:chef_server_root] = "http://www.example.com"
      @rest = double("rest")
      allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
    end

    describe "group" do
      it "should load group data when it's not loaded." do
        expect(@rest).to receive(:get_rest).with("organizations/myorg/groups/admins").and_return({})
        org.group("admins")
      end

      it "should not load group data a second time when it's already loaded." do
        expect(@rest).to receive(:get_rest)
          .with("organizations/myorg/groups/admins")
          .and_return({ anything: "goes" })
          .exactly(:once)
        admin1 = org.group("admins")
        admin2 = org.group("admins")
        expect(admin1).to eq admin2
      end
    end
  end
end
