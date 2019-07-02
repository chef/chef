# Copyright:: Copyright 2018, Chef Software, Inc
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
require "chef/resource_inspector"

class DummyResource < Chef::Resource
  resource_name :dummy
  description "A dummy resource"
  examples <<~EOH
    dummy "foo" do
      first "yes"
    end
  EOH
  introduced "14.0"
  property :first, String, description: "My First Property", introduced: "14.0"

  action :dummy do
    return true
  end
end

describe ResourceInspector do
  describe "inspecting a resource" do
    subject { ResourceInspector.extract_resource(DummyResource, false) }

    it "returns a hash with required data" do
      expect(subject[:description]).to eq "A dummy resource"
      expect(subject[:actions]).to match_array %i{nothing dummy}
    end

    context "excluding built in properties" do
      it "returns a single property" do
        expect(subject[:properties].count).to eq 1
        expect(subject[:properties].first[:name]).to eq :first
      end
    end

    context "including built in properties" do
      subject { ResourceInspector.extract_resource(DummyResource, true) }
      it "returns many properties" do
        expect(subject[:properties].count).to be > 1
        expect(subject[:properties].map { |n| n[:name] }).to include(:name, :first, :sensitive)
      end
    end
  end
end
