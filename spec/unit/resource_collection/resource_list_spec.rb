#
# Author:: Serdar Sutay (<serdar@chef.io>)
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

describe Chef::ResourceCollection::ResourceList do
  let(:resource_list) { Chef::ResourceCollection::ResourceList.new() }
  let(:resource) { Chef::Resource::ZenMaster.new("makoto") }
  let(:second_resource) { Chef::Resource::ZenMaster.new("hattori") }

  def insert_resource(res)
    expect { resource_list.insert(res) }.not_to raise_error
  end

  describe "initialize" do
    it "should return a Chef::ResourceList" do
      expect(resource_list).to be_instance_of(Chef::ResourceCollection::ResourceList)
    end
  end

  describe "insert" do
    it "should be able to insert a Chef::Resource" do
      insert_resource(resource)
      expect(resource_list[0]).to be(resource)
    end

    it "should insert things in order" do
      insert_resource(resource)
      insert_resource(second_resource)
      expect(resource_list[0]).to be(resource)
      expect(resource_list[1]).to be(second_resource)
    end

    it "should raise error when trying to install something other than Chef::Resource" do
      expect { resource_list.insert("not a resource") }.to raise_error(ArgumentError)
    end
  end

  describe "accessors" do
    it "should be able to insert with []=" do
      expect { resource_list[0] = resource }.not_to raise_error
      expect { resource_list[1] = second_resource }.not_to raise_error
      expect(resource_list[0]).to be(resource)
      expect(resource_list[1]).to be(second_resource)
    end

    it "should be empty by default" do
      expect(resource_list.empty?).to be_truthy
    end

    describe "when resources are inserted" do
      before do
        insert_resource(resource)
        insert_resource(second_resource)
      end

      it "should get resources with all_resources method" do
        resources = resource_list.all_resources

        expect(resources[0]).to be(resource)
        expect(resources[1]).to be(second_resource)
      end

      it "should be able to get resources with each" do
        current = 0
        expected_resources = [resource, second_resource]

        resource_list.each do |r|
          expect(r).to be(expected_resources[current])
          current += 1
        end

        expect(current).to eq(2)
      end

      it "should be able to get resources with each_index" do
        current = 0

        resource_list.each_index do |i|
          expect(i).to eq(current)
          current += 1
        end

        expect(current).to eq(2)
      end

      it "should be able to check if the list is empty" do
        expect(resource_list.empty?).to be_falsey
      end
    end
  end

  describe "during execute" do
    before(:each) do
      insert_resource(resource)
      insert_resource(second_resource)
    end

    it "should execute resources in order" do
      current = 0
      expected_resources = [resource, second_resource]

      resource_list.execute_each_resource do |r|
        expect(r).to be(expected_resources[current])
        current += 1
      end

      expect(current).to eq(2)
    end

    it "should be able to insert resources on the fly" do
      resource_to_inject = Chef::Resource::ZenMaster.new("there is no spoon")
      expected_resources = [resource, resource_to_inject, second_resource]

      resource_list.execute_each_resource do |r|
        resource_list.insert(resource_to_inject) if r == resource
      end

      expect(resource_list.all_resources).to eq(expected_resources)
    end
  end
end
