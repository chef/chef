# Copyright:: Copyright (c) Chef Software Inc.
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

require "knife_spec_helper"

describe Chef::Knife::Core::StatusPresenter do
  describe "#summarize_json" do
    let(:presenter) { Chef::Knife::Core::StatusPresenter.new(double(:ui), double(:config, :[] => "")) }

    let(:node) do
      Chef::Node.new.tap do |n|
        n.automatic_attrs["name"] = "my_node"
        n.automatic_attrs["ipaddress"] = "127.0.0.1"
      end
    end

    let(:result) { JSON.parse(presenter.summarize_json([node])).first }

    it "uses the first of public_ipv4_addrs when present" do
      node.automatic_attrs["cloud"] = { "public_ipv4_addrs" => ["2.2.2.2"] }

      expect(result["ip"]).to eq("2.2.2.2")
    end

    it "falls back to ipaddress when public_ipv4_addrs is empty" do
      node.automatic_attrs["cloud"] = { "public_ipv4_addrs" => [] }

      expect(result["ip"]).to eq("127.0.0.1")
    end

    it "falls back to ipaddress when cloud attributes are empty" do
      node.automatic_attrs["cloud"] = {}

      expect(result["ip"]).to eq("127.0.0.1")
    end

    it "falls back to ipaddress when cloud attributes is not present" do
      expect(result["ip"]).to eq("127.0.0.1")
    end
  end
end
