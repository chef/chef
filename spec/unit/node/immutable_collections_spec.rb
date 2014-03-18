#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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
require "chef/node/immutable_collections"

describe Chef::Node::ImmutableMash do
  before do
    @data_in = {:top => {:second_level => "some value"},
                "top_level_2" => %w[array of values],
                :top_level_3 => [{:hash_array => 1, :hash_array_b => 2}],
                :top_level_4 => {:level2 => {:key => "value"}}
    }
    @immutable_mash = Chef::Node::ImmutableMash.new(@data_in)
  end

  it "element references like regular hash" do
    @immutable_mash[:top][:second_level].should == "some value"
  end

  it "elelment references like a regular Mash" do
    @immutable_mash[:top_level_2].should == %w[array of values]
  end

  it "converts Hash-like inputs into ImmutableMash's" do
    @immutable_mash[:top].should be_a(Chef::Node::ImmutableMash)
  end

  it "converts array inputs into ImmutableArray's" do
    @immutable_mash[:top_level_2].should be_a(Chef::Node::ImmutableArray)
  end

  it "converts arrays of hashes to ImmutableArray's of ImmutableMashes" do
    @immutable_mash[:top_level_3].first.should be_a(Chef::Node::ImmutableMash)
  end

  it "converts nested hashes to ImmutableMashes" do
    @immutable_mash[:top_level_4].should be_a(Chef::Node::ImmutableMash)
    @immutable_mash[:top_level_4][:level2].should be_a(Chef::Node::ImmutableMash)
  end

  describe "to_hash" do
    before do
      @copy = @immutable_mash.to_hash
    end

    it "converts an immutable mash to a new mutable hash" do
      @copy.should be_instance_of(Hash)
    end

    it "converts an immutable nested mash to a new mutable hash" do
      @copy['top_level_4']['level2'].should be_instance_of(Hash)
    end

    it "converts an immutable nested array to a new mutable array" do
      @copy['top_level_2'].should be_instance_of(Array)
    end

    it "should create a mash with the same content" do
      @copy.should == @immutable_mash
    end

    it 'should allow mutation' do
      lambda { @copy['m'] = 'm' }.should_not raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

  end

  [
    :[]=,
    :clear,
    :default=,
    :default_proc=,
    :delete,
    :delete_if,
    :keep_if,
    :merge!,
    :update,
    :reject!,
    :replace,
    :select!,
    :shift
  ].each do |mutator|
    it "doesn't allow mutation via `#{mutator}'" do
      lambda { @immutable_mash.send(mutator) }.should raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_mash.dup
    mutable[:new_key] = :value
    mutable[:new_key].should == :value
  end

end

describe Chef::Node::ImmutableArray do

  before do
    @immutable_array = Chef::Node::ImmutableArray.new(%w[foo bar baz] + Array(1..3) + [nil, true, false, [ "el", 0, nil ] ])
    immutable_mash = Chef::Node::ImmutableMash.new({:m => 'm'})
    @immutable_nested_array = Chef::Node::ImmutableArray.new(["level1",@immutable_array, immutable_mash])
  end

  ##
  # Note: other behaviors, such as immutibilizing input data, are tested along
  # with ImmutableMash, above
  ###

  [
    :<<,
    :[]=,
    :clear,
    :collect!,
    :compact!,
    :default=,
    :default_proc=,
    :delete,
    :delete_at,
    :delete_if,
    :fill,
    :flatten!,
    :insert,
    :keep_if,
    :map!,
    :merge!,
    :pop,
    :push,
    :update,
    :reject!,
    :reverse!,
    :replace,
    :select!,
    :shift,
    :slice!,
    :sort!,
    :sort_by!,
    :uniq!,
    :unshift
  ].each do |mutator|
    it "does not allow mutation via `#{mutator}" do
      lambda { @immutable_array.send(mutator)}.should raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

  it "can be duped even if some elements can't" do
    @immutable_array.dup
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_array.dup
    mutable[0] = :value
    mutable[0].should == :value
  end

  describe "to_a" do
    before do
      @copy = @immutable_nested_array.to_a
    end

    it "converts an immutable array to a new mutable array" do
      @copy.should be_instance_of(Array)
    end

    it "converts an immutable nested array to a new mutable array" do
      @copy[1].should be_instance_of(Array)
    end

    it "converts an immutable nested mash to a new mutable hash" do
      @copy[2].should be_instance_of(Hash)
    end

    it "should create an array with the same content" do
      @copy.should == @immutable_nested_array
    end

    it 'should allow mutation' do
      lambda { @copy << 'm' }.should_not raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

end

