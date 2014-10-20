#
# Author:: Serdar Sutay (<serdar@getchef.com>)
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

describe Chef::ResourceCollection::ResourceList do
  let(:resource_list) { Chef::ResourceCollection::ResourceList.new() }
  let(:resource) { Chef::Resource::ZenMaster.new("makoto") }
  let(:second_resource) { Chef::Resource::ZenMaster.new("hattori") }

  describe "initialize" do
    it "should return a Chef::ResourceList" do
      expect(resource_list).to be_instance_of(Chef::ResourceCollection::ResourceList)
    end
  end

  describe "insert" do
    it "should be able to insert a Chef::Resource" do
      lambda { resource_list.insert(resource) }.should_not raise_error
      resource_list[0].should be(resource)
    end

    it "should insert things in order" do
      lambda { resource_list.insert(resource) }.should_not raise_error
      lambda { resource_list.insert(second_resource) }.should_not raise_error
      resource_list[0].should be(resource)
      resource_list[1].should be(second_resource)
    end

    it "should raise error when trying to install something other than Chef::Resource" do
      lambda { resource_list.insert("not a resource") }.should raise_error(ArgumentError)
    end
  end

  describe "accessors" do
    it "should be able to insert with []=" do
      lambda { resource_list[0] = resource }.should_not raise_error
      lambda { resource_list[1] = second_resource }.should_not raise_error
      resource_list[0].should be(resource)
      resource_list[1].should be(second_resource)
    end

    it "should be empty by default" do
      resource_list.empty?.should be_true
    end

    describe "when resources are inserted" do
      before do
        lambda { resource_list.insert(resource) }.should_not raise_error
        lambda { resource_list.insert(second_resource) }.should_not raise_error
      end

      it "should get resources with all_resources method" do
        resources = resource_list.all_resources

        resources[0].should be(resource)
        resources[1].should be(second_resource)
      end

      it "should be able to get resources with each" do
        current = 0

        resource_list.each do |r|
          case current
          when 0
            r.should be(resource)
            current += 1
          when 1
            r.should be(second_resource)
          else
            raise "Unexpected resource"
          end
        end

        current.should eq(1)
      end

      it "should be able to get resources with each_index" do
        current = 0

        resource_list.each_index do |i|
          i.should eq(current)
          current += 1
        end

        current.should eq(2)
      end

      it "should be able to check if the list is empty" do
        resource_list.empty?.should be_false
      end
    end
  end

  describe "during execute" do
    before(:each) do
      lambda { resource_list.insert(resource) }.should_not raise_error
      lambda { resource_list.insert(second_resource) }.should_not raise_error
    end

    it "should execute resources in order" do
      current = 0

      resource_list.execute_each_resource do |r|
        case current
        when 0
          r.should be(resource)
          current += 1
        when 1
          r.should be(second_resource)
        else
          raise "Unexpected resource"
        end
      end

      current.should eq(1)
    end

    it "should be able to insert resources on the fly" do
      current = 0
      resource_to_inject = Chef::Resource::ZenMaster.new("there is no spoon")

      resource_list.execute_each_resource do |r|
        case current
        when 0
          r.should be(resource)
          resource_list.insert(resource_to_inject)
          current += 1
        when 1
          r.should be(resource_to_inject)
          current += 1
        when 2
          r.should be(second_resource)
          current += 1
        else
          raise "Unexpected resource"
        end
      end

      resource_list.all_resources.count.should eq(3)
    end
  end
end
