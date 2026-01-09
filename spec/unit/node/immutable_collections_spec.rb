#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require "chef/node/immutable_collections"

shared_examples_for "ImmutableMash module" do |param|
  let(:copy) { @immutable_mash.send(param) }

  it "converts an immutable mash to a new mutable hash" do
    expect(copy).to be_is_a(Hash)
  end

  it "converts an immutable nested mash to a new mutable hash" do
    expect(copy["top_level_4"]["level2"]).to be_is_a(Hash)
  end

  it "converts an immutable nested array to a new mutable array" do
    expect(copy["top_level_2"]).to be_instance_of(Array)
  end

  it "should create a mash with the same content" do
    expect(copy).to eq(@immutable_mash)
  end

  it "should allow mutation" do
    expect { copy["m"] = "m" }.not_to raise_error
  end
end

shared_examples_for "ImmutableArray module" do |param|
  let(:copy) { @immutable_nested_array.send(param) }

  it "converts an immutable array to a new mutable array" do
    expect(copy).to be_instance_of(Array)
  end

  it "converts an immutable nested array to a new mutable array" do
    expect(copy[1]).to be_instance_of(Array)
  end

  it "converts an immutable nested mash to a new mutable hash" do
    expect(copy[2]).to be_is_a(Hash)
  end

  it "should create an array with the same content" do
    expect(copy).to eq(@immutable_nested_array)
  end

  it "should allow mutation" do
    expect { copy << "m" }.not_to raise_error
  end
end

shared_examples_for "Immutable#to_yaml" do
  it "converts an immutable array to a new valid YAML mutable string" do
    expect { YAML.parse(copy) }.not_to raise_error
  end

  it "should create a YAML string with content" do
    # Roundtrip the test string through YAML to compensate for some changes in libyaml-0.2.5
    # See: https://github.com/yaml/libyaml/pull/186
    expected = YAML.dump(YAML.load(parsed_yaml))

    expect(copy).to eq(expected)
  end
end

describe Chef::Node::ImmutableMash do
  before do
    @data_in = { "top" => { "second_level" => "some value" },
                 "top_level_2" => %w{array of values},
                 "top_level_3" => [{ "hash_array" => 1, "hash_array_b" => 2 }],
                 "top_level_4" => { "level2" => { "key" => "value" } },
    }
    @immutable_mash = Chef::Node::ImmutableMash.new(@data_in)
  end

  it "does not have any unaudited methods" do
    unaudited_methods = Hash.instance_methods - Object.instance_methods - Chef::Node::Mixin::ImmutablizeHash::DISALLOWED_MUTATOR_METHODS - Chef::Node::Mixin::ImmutablizeHash::ALLOWED_METHODS
    expect(unaudited_methods).to be_empty
  end

  it "element references like regular hash" do
    expect(@immutable_mash[:top][:second_level]).to eq("some value")
  end

  it "element references like a regular Mash" do
    expect(@immutable_mash[:top_level_2]).to eq(%w{array of values})
  end

  it "converts Hash-like inputs into ImmutableMash's" do
    expect(@immutable_mash[:top]).to be_a(Chef::Node::ImmutableMash)
  end

  it "converts array inputs into ImmutableArray's" do
    expect(@immutable_mash[:top_level_2]).to be_a(Chef::Node::ImmutableArray)
  end

  it "converts arrays of hashes to ImmutableArray's of ImmutableMashes" do
    expect(@immutable_mash[:top_level_3].first).to be_a(Chef::Node::ImmutableMash)
  end

  it "converts nested hashes to ImmutableMashes" do
    expect(@immutable_mash[:top_level_4]).to be_a(Chef::Node::ImmutableMash)
    expect(@immutable_mash[:top_level_4][:level2]).to be_a(Chef::Node::ImmutableMash)
  end

  # we only ever absorb VividMashes from other precedence levels, which already have
  # been coerced to only have string keys, so we do not need to do that work twice (performance).
  it "does not call convert_value like Mash/VividMash" do
    @mash = Chef::Node::ImmutableMash.new({ test: "foo", "test2" => "bar" })
    expect(@mash[:test]).to eql("foo")
    expect(@mash["test2"]).to eql("bar")
  end

  %w{to_h to_hash dup}.each do |immutable_meth|
    describe immutable_meth do
      include_examples "ImmutableMash module", description
    end
  end

  describe "to_yaml" do
    let(:copy) { @immutable_mash.to_yaml }
    let(:parsed_yaml) { "---\ntop:\n  second_level: some value\ntop_level_2:\n- array\n- of\n- values\ntop_level_3:\n- hash_array: 1\n  hash_array_b: 2\ntop_level_4:\n  level2:\n    key: value\n" }

    include_examples "Immutable#to_yaml"
  end

  %i{
    []=
    clear
    default=
    default_proc=
    delete
    delete_if
    keep_if
    merge!
    update
    reject!
    replace
    select!
    shift
    write
    write!
    unlink
    unlink!
  }.each do |mutator|
    it "doesn't allow mutation via `#{mutator}'" do
      expect { @immutable_mash.send(mutator) }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_mash.dup
    mutable[:new_key] = :value
    expect(mutable[:new_key]).to eq(:value)
  end

end

describe Chef::Node::ImmutableArray do

  before do
    @immutable_array = Chef::Node::ImmutableArray.new(%w{foo bar baz} + Array(1..3) + [nil, true, false, [ "el", 0, nil ] ])
    immutable_mash = Chef::Node::ImmutableMash.new({ "m" => "m" })
    @immutable_nested_array = Chef::Node::ImmutableArray.new(["level1", @immutable_array, immutable_mash])
  end

  ##
  # Note: other behaviors, such as immutibilizing input data, are tested along
  # with ImmutableMash, above
  ###

  %i{
    <<
    []=
    clear
    collect!
    compact!
    default=
    default_proc=
    delete
    delete_at
    delete_if
    fill
    flatten!
    insert
    keep_if
    map!
    merge!
    pop
    push
    reject!
    reverse!
    replace
    select!
    shift
    slice!
    sort!
    sort_by!
    uniq!
    unshift
  }.each do |mutator|
    it "does not allow mutation via `#{mutator}" do
      expect { @immutable_array.send(mutator) }.to raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end
  end

  it "does not have any unaudited methods" do
    unaudited_methods = Array.instance_methods - Object.instance_methods - Chef::Node::Mixin::ImmutablizeArray::DISALLOWED_MUTATOR_METHODS - Chef::Node::Mixin::ImmutablizeArray::ALLOWED_METHODS
    expect(unaudited_methods).to be_empty
  end

  it "can be duped even if some elements can't" do
    @immutable_array.dup
  end

  it "returns a mutable version of itself when duped" do
    mutable = @immutable_array.dup
    mutable[0] = :value
    expect(mutable[0]).to eq(:value)
  end

  %w{to_a to_array dup}.each do |immutable_meth|
    describe immutable_meth do
      include_examples "ImmutableArray module", description
    end
  end

  describe "to_yaml" do
    let(:copy) { @immutable_nested_array.to_yaml }
    let(:parsed_yaml) { "---\n- level1\n- - foo\n  - bar\n  - baz\n  - 1\n  - 2\n  - 3\n  -\n  - true\n  - false\n  - - el\n    - 0\n    -\n- m: m\n" }

    include_examples "Immutable#to_yaml"
  end

  describe "#[]" do
    it "works with array slices" do
      expect(@immutable_array[1, 2]).to eql(%w{bar baz})
    end
  end
end
