#
# Author:: Jay Mundrawala <jdm@chef.io>
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

require "chef"
require "chef/util/dsc/resource_store"

describe Chef::Util::DSC::ResourceStore do
  let(:resource_store) { Chef::Util::DSC::ResourceStore.new }
  let(:resource_a) do
    {
    "ResourceType" => "AFoo",
    "Name" => "Foo",
    "Module" => { "Name" => "ModuleA" },
    }
  end

  let(:resource_b) do
    {
    "ResourceType" => "BFoo",
    "Name" => "Foo",
    "Module" => { "Name" => "ModuleB" },
    }
  end

  context "when resources are not cached" do
    context "when calling #resources" do
      it "returns an empty array" do
        expect(resource_store.resources).to eql([])
      end
    end

    context "when calling #find" do
      it "returns an empty list if it cannot find any matching resources" do
        expect(resource_store).to receive(:query_resource).and_return([])
        expect(resource_store.find("foo")).to eql([])
      end

      it "returns the resource if it is found (comparisons are case insensitive)" do
        expect(resource_store).to receive(:query_resource).and_return([resource_a])
        expect(resource_store.find("foo")).to eql([resource_a])
      end

      it "returns multiple resoures if they are found" do
        expect(resource_store).to receive(:query_resource).and_return([resource_a, resource_b])
        expect(resource_store.find("foo")).to include(resource_a, resource_b)
      end

      it "deduplicates resources by ResourceName" do
        expect(resource_store).to receive(:query_resource).and_return([resource_a, resource_a])
        resource_store.find("foo")
        expect(resource_store.resources).to eq([resource_a])
      end
    end
  end

  context "when resources are cached" do
    it "recalls resources from the cache if present" do
      expect(resource_store).not_to receive(:query_resource)
      expect(resource_store).to receive(:resources).and_return([resource_a])
      resource_store.find("foo")
    end
  end
end
