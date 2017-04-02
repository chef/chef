#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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

describe Chef::ResourceCollection::ResourceSet do
  let(:collection) { Chef::ResourceCollection::ResourceSet.new }

  let(:zen_master_name) { "Neo" }
  let(:zen_master2_name) { "Morpheus" }
  let(:zen_follower_name) { "Squid" }
  let(:zen_master) { Chef::Resource::ZenMaster.new(zen_master_name) }
  let(:zen_master2) { Chef::Resource::ZenMaster.new(zen_master2_name) }
  let(:zen_follower) { Chef::Resource::ZenFollower.new(zen_follower_name) }
  let(:zen_array) { Chef::Resource::ZenMaster.new( [ zen_master_name, zen_master2_name ]) }

  describe "initialize" do
    it "should return a Chef::ResourceSet" do
      expect(collection).to be_instance_of(Chef::ResourceCollection::ResourceSet)
    end
  end

  describe "keys" do
    it "should return an empty list for an empty ResourceSet" do
      expect(collection.keys).to eq([])
    end

    it "should return the keys for a non-empty ResourceSet" do
      collection.instance_variable_get(:@resources_by_key)["key"] = nil
      expect(collection.keys).to eq(["key"])
    end
  end

  describe "insert_as, lookup and find" do
    # To validate insert_as you need lookup, and vice-versa - putting all tests in 1 context to avoid duplication
    it "should accept only Chef::Resources" do
      expect { collection.insert_as(zen_master) }.to_not raise_error
      expect { collection.insert_as("string") }.to raise_error(ArgumentError)
    end

    it "should allow you to lookup resources by a default .to_s" do
      collection.insert_as(zen_master)
      expect(collection.lookup(zen_master.to_s)).to equal(zen_master)
    end

    it "should use a custom type and name to insert" do
      collection.insert_as(zen_master, "OtherResource", "other_resource")
      expect(collection.lookup("OtherResource[other_resource]")).to equal(zen_master)
    end

    it "should raise an exception if you send something strange to lookup" do
      expect { collection.lookup(:symbol) }.to raise_error(ArgumentError)
    end

    it "should raise an exception if it cannot find a resource with lookup" do
      expect { collection.lookup(zen_master.to_s) }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    it "should find a resource by type symbol and name" do
      collection.insert_as(zen_master)
      expect(collection.find(:zen_master => zen_master_name)).to equal(zen_master)
    end

    it "should find a resource by type symbol and array of names" do
      collection.insert_as(zen_master)
      collection.insert_as(zen_master2)
      check_by_names(collection.find(:zen_master => [zen_master_name, zen_master2_name]), zen_master_name, zen_master2_name)
    end

    it "should find a resource by type symbol and array of names with custom names" do
      collection.insert_as(zen_master, :zzz, "name1")
      collection.insert_as(zen_master2, :zzz, "name2")
      check_by_names(collection.find( :zzz => %w{name1 name2}), zen_master_name, zen_master2_name)
    end

    it "should find resources of multiple kinds (:zen_master => a, :zen_follower => b)" do
      collection.insert_as(zen_master)
      collection.insert_as(zen_follower)
      check_by_names(collection.find(:zen_master => [zen_master_name], :zen_follower => [zen_follower_name]),
                     zen_master_name, zen_follower_name)
    end

    it "should find resources of multiple kinds (:zen_master => a, :zen_follower => b with custom names)" do
      collection.insert_as(zen_master, :zzz, "name1")
      collection.insert_as(zen_master2, :zzz, "name2")
      collection.insert_as(zen_follower, :yyy, "name3")
      check_by_names(collection.find(:zzz => %w{name1 name2}, :yyy => ["name3"]),
                     zen_master_name, zen_follower_name, zen_master2_name)
    end

    it "should find a resource by string zen_master[a]" do
      collection.insert_as(zen_master)
      expect(collection.find("zen_master[#{zen_master_name}]")).to eq(zen_master)
    end

    it "should find a resource by string zen_master[a] with custom names" do
      collection.insert_as(zen_master, :zzz, "name1")
      expect(collection.find("zzz[name1]")).to eq(zen_master)
    end

    it "should find resources by strings of zen_master[a,b]" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      collection.insert_as(zen_master)
      collection.insert_as(zen_master2)
      check_by_names(collection.find("zen_master[#{zen_master_name},#{zen_master2_name}]"),
                     zen_master_name, zen_master2_name)
    end

    it "should find array names" do
      collection.insert_as(zen_array)
      expect(collection.find("zen_master[#{zen_master_name}, #{zen_master2_name}]")).to eql(zen_array)
    end

    it "should favor array names over multi resource syntax" do
      collection.insert_as(zen_master)
      collection.insert_as(zen_master2)
      collection.insert_as(zen_array)
      expect(collection.find("zen_master[#{zen_master_name}, #{zen_master2_name}]")).to eql(zen_array)
    end

    it "should find resources by strings of zen_master[a,b] with custom names" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      collection.insert_as(zen_master, :zzz, "name1")
      collection.insert_as(zen_master2, :zzz, "name2")
      check_by_names(collection.find("zzz[name1,name2]"),
                     zen_master_name, zen_master2_name)
    end

    it "should find resources of multiple types by strings of zen_master[a]" do
      collection.insert_as(zen_master)
      collection.insert_as(zen_follower)
      check_by_names(collection.find("zen_master[#{zen_master_name}]", "zen_follower[#{zen_follower_name}]"),
                     zen_master_name, zen_follower_name)
    end

    it "should find resources of multiple types by strings of zen_master[a] with custom names" do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      collection.insert_as(zen_master, :zzz, "name1")
      collection.insert_as(zen_master2, :zzz, "name2")
      collection.insert_as(zen_follower, :yyy, "name3")
      check_by_names(collection.find("zzz[name1,name2]", "yyy[name3]"),
                     zen_master_name, zen_follower_name, zen_master2_name)
    end

    it "should only keep the last copy when multiple instances of a Resource are inserted" do
      collection.insert_as(zen_master)
      expect(collection.find("zen_master[#{zen_master_name}]")).to eq(zen_master)
      new_zm = zen_master.dup
      new_zm.retries = 10
      expect(new_zm).to_not eq(zen_master)
      collection.insert_as(new_zm)
      expect(collection.find("zen_master[#{zen_master_name}]")).to eq(new_zm)
    end

    it "should raise an exception if you pass a bad name to resources" do
      expect { collection.find("michael jackson") }.to raise_error(ArgumentError)
    end

    it "should raise an exception if you pass something other than a string or hash to resource" do
      expect { collection.find([Array.new]) }.to raise_error(ArgumentError)
    end

    it "raises an error when attempting to find a resource that does not exist" do
      expect { collection.find("script[nonesuch]") }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end

    context "nameless resources" do
      let(:zen_master_name) { "" }

      it "looks up nameless resources with find without brackets" do
        collection.insert_as(zen_master)
        expect(collection.find("zen_master")).to eq(zen_master)
      end

      it "looks up nameless resources with find with empty brackets" do
        collection.insert_as(zen_master)
        expect(collection.find("zen_master[]")).to eq(zen_master)
      end

      it "looks up nameless resources with find with empty string hash key" do
        collection.insert_as(zen_master)
        expect(collection.find(zen_master: "")).to eq(zen_master)
      end

      it "looks up nameless resources with lookup with empty brackets" do
        collection.insert_as(zen_master)
        expect(collection.lookup("zen_master[]")).to eq(zen_master)
      end

      it "looks up nameless resources with lookup with the resource" do
        collection.insert_as(zen_master)
        expect(collection.lookup(zen_master)).to eq(zen_master)
      end
    end
  end

  describe "validate_lookup_spec!" do
    it "accepts a string of the form 'resource_type[resource_name]'" do
      expect(collection.validate_lookup_spec!("resource_type[resource_name]")).to be_truthy
    end

    it "accepts a single-element :resource_type => 'resource_name' Hash" do
      expect(collection.validate_lookup_spec!(:service => "apache2")).to be_truthy
    end

    it "accepts a chef resource object" do
      expect(collection.validate_lookup_spec!(zen_master)).to be_truthy
    end

    it "rejects a malformed query string" do
      expect { collection.validate_lookup_spec!("resource_type[missing-end-bracket") }.to \
        raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end

    it "rejects an argument that is not a String, Hash, or Chef::Resource" do
      expect { collection.validate_lookup_spec!(Object.new) }.to \
        raise_error(Chef::Exceptions::InvalidResourceSpecification)
    end

  end

  def check_by_names(results, *names)
    expect(results.size).to eq(names.size)
    names.each do |name|
      expect(results.detect { |r| r.name == name }).to_not eq(nil)
    end
  end

end
