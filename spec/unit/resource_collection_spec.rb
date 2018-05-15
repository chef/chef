#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

describe Chef::ResourceCollection do
  let(:rc) { Chef::ResourceCollection.new() }
  let(:resource) { Chef::Resource::ZenMaster.new("makoto") }

  it "should throw an error when calling a non-delegated method" do
    expect { rc.not_a_method }.to raise_error(NoMethodError)
  end

  describe "initialize" do
    it "should return a Chef::ResourceCollection" do
      expect(rc).to be_kind_of(Chef::ResourceCollection)
    end
  end

  describe "[]" do
    it "should accept Chef::Resources through [index]" do
      expect { rc[0] = resource }.not_to raise_error
      expect { rc[0] = "string" }.to raise_error(ArgumentError)
    end

    it "should allow you to fetch Chef::Resources by position" do
      rc[0] = resource
      expect(rc[0]).to eql(resource)
    end
  end

  describe "push" do
    it "should accept Chef::Resources through pushing" do
      expect { rc.push(resource) }.not_to raise_error
      expect { rc.push("string") }.to raise_error(ArgumentError)
    end
  end

  describe "<<" do
    it "should accept the << operator" do
      expect { rc << resource }.not_to raise_error
    end
  end

  describe "insert" do
    it "should accept only Chef::Resources" do
      expect { rc.insert(resource) }.not_to raise_error
      expect { rc.insert("string") }.to raise_error(ArgumentError)
    end

    it "should accept named arguments in any order" do
      rc.insert(resource, :instance_name => "foo", :resource_type => "bar")
      expect(rc[0]).to eq(resource)
    end

    it "should append resources to the end of the collection when not executing a run" do
      zmr = Chef::Resource::ZenMaster.new("there is no spoon")
      rc.insert(resource)
      rc.insert(zmr)
      expect(rc[0]).to eql(resource)
      expect(rc[1]).to eql(zmr)
    end

    it "should insert resources to the middle of the collection if called while executing a run" do
      resource_to_inject = Chef::Resource::ZenMaster.new("there is no spoon")
      zmr = Chef::Resource::ZenMaster.new("morpheus")
      dummy = Chef::Resource::ZenMaster.new("keanu reeves")
      rc.insert(zmr)
      rc.insert(dummy)

      rc.execute_each_resource do |resource|
        rc.insert(resource_to_inject) if resource == zmr
      end

      expect(rc[0]).to eql(zmr)
      expect(rc[1]).to eql(resource_to_inject)
      expect(rc[2]).to eql(dummy)
    end
  end

  describe "each" do
    it "should allow you to iterate over every resource in the collection" do
      load_up_resources
      results = Array.new
      expect do
        rc.each do |r|
          results << r.name
        end
      end.not_to raise_error
      results.each_index do |i|
        case i
        when 0
          expect(results[i]).to eql("dog")
        when 1
          expect(results[i]).to eql("cat")
        when 2
          expect(results[i]).to eql("monkey")
        end
      end
    end
  end

  describe "each_index" do
    it "should allow you to iterate over every resource by index" do
      load_up_resources
      results = Array.new
      expect do
        rc.each_index do |i|
          results << rc[i].name
        end
      end.not_to raise_error
      results.each_index do |i|
        case i
        when 0
          expect(results[i]).to eql("dog")
        when 1
          expect(results[i]).to eql("cat")
        when 2
          expect(results[i]).to eql("monkey")
        end
      end
    end
  end

  describe "lookup" do
    it "should allow you to find resources by name via lookup" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      rc << zmr
      expect(rc.lookup(zmr.to_s)).to eql(zmr)

      zmr = Chef::Resource::ZenMaster.new("cat")
      rc[0] = zmr
      expect(rc.lookup(zmr)).to eql(zmr)

      zmr = Chef::Resource::ZenMaster.new("monkey")
      rc.push(zmr)
      expect(rc.lookup(zmr)).to eql(zmr)
    end

    it "should raise an exception if you send something strange to lookup" do
      expect { rc.lookup(:symbol) }.to raise_error(ArgumentError)
    end

    it "should raise an exception if it cannot find a resource with lookup" do
      expect { rc.lookup("zen_master[dog]") }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end
  end

  describe "delete" do
    it "should allow you to delete resources by name via delete" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      rc << zmr
      expect(rc).not_to be_empty
      expect(rc.delete(zmr.to_s)).to eql(zmr)
      expect(rc).to be_empty

      zmr = Chef::Resource::ZenMaster.new("cat")
      rc[0] = zmr
      expect(rc).not_to be_empty
      expect(rc.delete(zmr)).to eql(zmr)
      expect(rc).to be_empty

      zmr = Chef::Resource::ZenMaster.new("monkey")
      rc.push(zmr)
      expect(rc).not_to be_empty
      expect(rc.delete(zmr)).to eql(zmr)
      expect(rc).to be_empty
    end

    it "should raise an exception if you send something strange to delete" do
      expect { rc.delete(:symbol) }.to raise_error(ArgumentError)
    end

    it "should raise an exception if it cannot find a resource with delete" do
      expect { rc.delete("zen_master[dog]") }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end
  end

  describe "resources" do

    it "should find a resource by symbol and name (:zen_master => monkey)" do
      load_up_resources
      expect(rc.resources(:zen_master => "monkey").name).to eql("monkey")
    end

    it "should find a resource by symbol and array of names (:zen_master => [a,b])" do
      load_up_resources
      results = rc.resources(:zen_master => %w{monkey dog})
      expect(results.length).to eql(2)
      check_by_names(results, "monkey", "dog")
    end

    it "should find resources of multiple kinds (:zen_master => a, :file => b)" do
      load_up_resources
      results = rc.resources(:zen_master => "monkey", :file => "something")
      expect(results.length).to eql(2)
      check_by_names(results, "monkey", "something")
    end

    it "should find a resource by string zen_master[a]" do
      load_up_resources
      expect(rc.resources("zen_master[monkey]").name).to eql("monkey")
    end

    it "should find resources by strings of zen_master[a,b]" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      load_up_resources
      results = rc.resources("zen_master[monkey,dog]")
      expect(results.length).to eql(2)
      check_by_names(results, "monkey", "dog")
    end

    it "should find resources of multiple types by strings of zen_master[a]" do
      load_up_resources
      results = rc.resources("zen_master[monkey]", "file[something]")
      expect(results.length).to eql(2)
      check_by_names(results, "monkey", "something")
    end

    it "should raise an exception if you pass a bad name to resources" do
      expect { rc.resources("michael jackson") }.to raise_error(ArgumentError)
    end

    it "should raise an exception if you pass something other than a string or hash to resource" do
      expect { rc.resources([Array.new]) }.to raise_error(ArgumentError)
    end

    it "raises an error when attempting to find a resource that does not exist" do
      expect { rc.find("script[nonesuch]") }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

  end

  describe "when validating a resource query object" do
    it "accepts a string of the form 'resource_type[resource_name]'" do
      expect(rc.validate_lookup_spec!("resource_type[resource_name]")).to be_truthy
    end

    it "accepts a single-element :resource_type => 'resource_name' Hash" do
      expect(rc.validate_lookup_spec!(:service => "apache2")).to be_truthy
    end

    it "accepts a chef resource object" do
      res = Chef::Resource.new("foo", nil)
      expect(rc.validate_lookup_spec!(res)).to be_truthy
    end

    it "rejects a malformed query string" do
      expect do
        rc.validate_lookup_spec!("resource_type[missing-end-bracket")
      end.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end

    it "rejects an argument that is not a String, Hash, or Chef::Resource" do
      expect do
        rc.validate_lookup_spec!(Object.new)
      end.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end

  end

  describe "to_json" do
    it "should serialize to json" do
      json = rc.to_json
      expect(json).to match(/json_class/)
      expect(json).to match(/instance_vars/)
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { rc }
    end
  end

  describe "self.from_json" do
    it "should not respond to this method" do
      expect(rc.respond_to?(:from_json)).to eq(false)
    end

    it "should convert from json using the Chef::JSONCompat library" do
      rc << resource
      json = Chef::JSONCompat.to_json(rc)
      s_rc = Chef::ResourceCollection.from_json(json)
      expect(s_rc).to be_a_kind_of(Chef::ResourceCollection)
      expect(s_rc[0].name).to eql(resource.name)
    end
  end

  describe "provides access to the raw resources array" do
    it "returns the resources via the all_resources method" do
      expect(rc.all_resources).to equal(rc.instance_variable_get(:@resource_list).instance_variable_get(:@resources))
    end
  end

  describe "provides access to stepable iterator" do
    it "returns the iterator object" do
      rc.instance_variable_get(:@resource_list).instance_variable_set(:@iterator, :fooboar)
      expect(rc.iterator).to eq(:fooboar)
    end
  end

  describe "multiple run_contexts" do
    let(:node) { Chef::Node.new }
    let(:parent_run_context) { Chef::RunContext.new(node, {}, nil) }
    let(:parent_resource_collection) { parent_run_context.resource_collection }
    let(:child_run_context) { parent_run_context.create_child }
    let(:child_resource_collection) { child_run_context.resource_collection }

    it "should find resources in the parent run_context with lookup" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      parent_resource_collection << zmr
      expect(child_resource_collection.lookup(zmr.to_s)).to eql(zmr)
    end

    it "should not find resources in the parent run_context with lookup_local" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      parent_resource_collection << zmr
      expect { child_resource_collection.lookup_local(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "should find resources in the child run_context with lookup_local" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      child_resource_collection << zmr
      expect(child_resource_collection.lookup_local(zmr.to_s)).to eql(zmr)
    end

    it "should find resources in the parent run_context with find" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      parent_resource_collection << zmr
      expect(child_resource_collection.find(zmr.to_s)).to eql(zmr)
    end

    it "should not find resources in the parent run_context with find_local" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      parent_resource_collection << zmr
      expect { child_resource_collection.find_local(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "should find resources in the child run_context with find_local" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      child_resource_collection << zmr
      expect(child_resource_collection.find_local(zmr.to_s)).to eql(zmr)
    end

    it "should not find resources in the child run_context in any way from the parent" do
      zmr = Chef::Resource::ZenMaster.new("dog")
      child_resource_collection << zmr
      expect { parent_resource_collection.find_local(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
      expect { parent_resource_collection.find(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
      expect { parent_resource_collection.lookup_local(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
      expect { parent_resource_collection.lookup(zmr.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "should behave correctly when there is an identically named resource in the child and parent" do
      a = Chef::Resource::File.new("something")
      a.content("foo")
      parent_resource_collection << a
      b = Chef::Resource::File.new("something")
      b.content("bar")
      child_resource_collection << b
      expect(child_resource_collection.find_local("file[something]").content).to eql("bar")
      expect(child_resource_collection.find("file[something]").content).to eql("bar")
      expect(child_resource_collection.lookup_local("file[something]").content).to eql("bar")
      expect(child_resource_collection.lookup("file[something]").content).to eql("bar")
      expect(parent_resource_collection.find_local("file[something]").content).to eql("foo")
      expect(parent_resource_collection.find("file[something]").content).to eql("foo")
      expect(parent_resource_collection.lookup_local("file[something]").content).to eql("foo")
      expect(parent_resource_collection.lookup("file[something]").content).to eql("foo")
    end
  end

  def check_by_names(results, *names)
    names.each do |res_name|
      expect(results.detect { |res| res.name == res_name }).not_to eql(nil)
    end
  end

  def load_up_resources
    %w{dog cat monkey}.each do |n|
      rc << Chef::Resource::ZenMaster.new(n)
    end
    rc << Chef::Resource::File.new("something")
  end

end
