#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Author:: Steve Midgley (http://www.misuse.org/science)
# Copyright:: Copyright 2010-2016, Matthew Kent
# Copyright:: Copyright 2008-2016, Steve Midgley
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

# Notice:
# This code is imported from deep_merge by Steve Midgley. deep_merge is
# available under the MIT license from
# http://trac.misuse.org/science/wiki/DeepMerge

require "spec_helper"

# Test coverage from the original author converted to rspec
describe Chef::Mixin::DeepMerge, "deep_merge!" do
  before do
    @dm = Chef::Mixin::DeepMerge
    @field_ko_prefix = "!merge"
  end

  # deep_merge core tests - moving from basic to more complex

  it "tests merging an hash w/array into blank hash" do
    hash_src = { "id" => "2" }
    hash_dst = {}
    @dm.deep_merge!(hash_src.dup, hash_dst)
    expect(hash_dst).to eq(hash_src)
  end

  it "tests merging an hash w/array into blank hash" do
    hash_src = { "region" => { "id" => %w{227 2} } }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq(hash_src)
  end

  it "tests merge from empty hash" do
    hash_src = {}
    hash_dst = { "property" => %w{2 4} }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => %w{2 4} })
  end

  it "tests merge to empty hash" do
    hash_src = { "property" => %w{2 4} }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => %w{2 4} })
  end

  it "tests simple string overwrite" do
    hash_src = { "name" => "value" }
    hash_dst = { "name" => "value1" }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "name" => "value" })
  end

  it "tests simple string overwrite of empty hash" do
    hash_src = { "name" => "value" }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq(hash_src)
  end

  it "tests hashes holding array" do
    hash_src = { "property" => %w{1 3} }
    hash_dst = { "property" => %w{2 4} }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => %w{2 4 1 3} })
  end

  it "tests hashes holding hashes holding arrays (array with duplicate elements is merged with dest then src" do
    hash_src = { "property" => { "bedroom_count" => %w{1 2}, "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => %w{3 2}, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => %w{3 2 1}, "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests hash holding hash holding array v string (string is overwritten by array)" do
    hash_src = { "property" => { "bedroom_count" => %w{1 2}, "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => "3", "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => %w{1 2}, "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests hash holding hash holding string v array (array is overwritten by string)" do
    hash_src = { "property" => { "bedroom_count" => "3", "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => %w{1 2}, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => "3", "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests hash holding hash holding hash v array (array is overwritten by hash)" do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => 1 }, "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => %w{1 2}, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => 1 }, "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests 3 hash layers holding integers (integers are overwritten by source)" do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => 1 }, "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => 2, "queen_bed" => 4 }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => 1 }, "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests 3 hash layers holding arrays of int (arrays are merged)" do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => [3], "queen_bed" => [1] }, "bathroom_count" => ["1", "4+"] } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => [2, 3], "queen_bed" => [4, 1] }, "bathroom_count" => ["2", "1", "4+"] } })
  end

  it "tests 1 hash overwriting 3 hash layers holding arrays of int" do
    hash_src = { "property" => "1" }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => "1" })
  end

  it "tests 3 hash layers holding arrays of int (arrays are merged) but second hash's array is overwritten" do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => [3], "queen_bed" => [1] }, "bathroom_count" => "1" } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => [2, 3], "queen_bed" => [4, 1] }, "bathroom_count" => "1" } })
  end

  it "tests 3 hash layers holding arrays of int, but one holds int. This one overwrites, but the rest merge" do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => [1] }, "bathroom_count" => ["1"] } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => 3, "queen_bed" => [4, 1] }, "bathroom_count" => %w{2 1} } })
  end

  it "tests 3 hash layers holding arrays of int, but source is incomplete." do
    hash_src = { "property" => { "bedroom_count" => { "king_bed" => [3] }, "bathroom_count" => ["1"] } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => [2, 3], "queen_bed" => [4] }, "bathroom_count" => %w{2 1} } })
  end

  it "tests 3 hash layers holding arrays of int, but source is shorter and has new 2nd level ints." do
    hash_src = { "property" => { "bedroom_count" => { 2 => 3, "king_bed" => [3] }, "bathroom_count" => ["1"] } }
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { 2 => 3, "king_bed" => [2, 3], "queen_bed" => [4] }, "bathroom_count" => %w{2 1} } })
  end

  it "tests 3 hash layers holding arrays of int, but source is empty" do
    hash_src = {}
    hash_dst = { "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { "king_bed" => [2], "queen_bed" => [4] }, "bathroom_count" => ["2"] } })
  end

  it "tests 3 hash layers holding arrays of int, but dest is empty" do
    hash_src = { "property" => { "bedroom_count" => { 2 => 3, "king_bed" => [3] }, "bathroom_count" => ["1"] } }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => { 2 => 3, "king_bed" => [3] }, "bathroom_count" => ["1"] } })
  end

  it "tests hash holding arrays of arrays" do
    hash_src = { %w{1 2 3} => %w{1 2} }
    hash_dst = { %w{4 5} => ["3"] }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ %w{1 2 3} => %w{1 2}, %w{4 5} => ["3"] })
  end

  it "tests merging of hash with blank hash, and make sure that source array split does not function when turned off" do
    hash_src = { "property" => { "bedroom_count" => ["1", "2,3"] } }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "property" => { "bedroom_count" => ["1", "2,3"] } })
  end

  it "tests merging into a blank hash" do
    hash_src = { "action" => "browse", "controller" => "results" }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq(hash_src)
  end

  it "tests are unmerged hashes passed unmodified w/out :unpack_arrays?" do
    hash_src = { "amenity" => { "id" => ["26,27"] } }
    hash_dst = {}
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "amenity" => { "id" => ["26,27"] } })
  end

  it "tests hash of array of hashes" do
    hash_src = { "item" => [{ "1" => "3" }, { "2" => "4" }] }
    hash_dst = { "item" => [{ "3" => "5" }] }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "item" => [{ "3" => "5" }, { "1" => "3" }, { "2" => "4" }] })
  end

  # Additions since import
  it "should overwrite true with false when merging boolean values" do
    hash_src = { "valid" => false }
    hash_dst = { "valid" => true }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "valid" => false })
  end

  it "should overwrite false with true when merging boolean values" do
    hash_src = { "valid" => true }
    hash_dst = { "valid" => false }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "valid" => true })
  end

  it "should overwrite a string with an empty string when merging string values" do
    hash_src = { "item" => " " }
    hash_dst = { "item" => "orange" }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "item" => " " })
  end

  it "should overwrite an empty string with a string when merging string values" do
    hash_src = { "item" => "orange" }
    hash_dst = { "item" => " " }
    @dm.deep_merge!(hash_src, hash_dst)
    expect(hash_dst).to eq({ "item" => "orange" })
  end
end # deep_merge!

# Chef specific
describe Chef::Mixin::DeepMerge do
  before do
    @dm = Chef::Mixin::DeepMerge
  end

  describe "merge" do
    it "should merge a hash into an empty hash" do
      hash_dst = {}
      hash_src = { "id" => "2" }
      expect(@dm.merge(hash_dst, hash_src)).to eq(hash_src)
    end

    it "should merge a nested hash into an empty hash" do
      hash_dst = {}
      hash_src = { "region" => { "id" => %w{227 2} } }
      expect(@dm.merge(hash_dst, hash_src)).to eq(hash_src)
    end

    it "should overwrite as string value when merging hashes" do
      hash_dst = { "name" => "value1" }
      hash_src = { "name" => "value" }
      expect(@dm.merge(hash_dst, hash_src)).to eq({ "name" => "value" })
    end

    it "should merge arrays within hashes" do
      hash_dst = { "property" => %w{2 4} }
      hash_src = { "property" => %w{1 3} }
      expect(@dm.merge(hash_dst, hash_src)).to eq({ "property" => %w{2 4 1 3} })
    end

    it "should merge deeply nested hashes" do
      hash_dst = { "property" => { "values" => { "are" => "falling", "can" => "change" } } }
      hash_src = { "property" => { "values" => { "are" => "stable", "may" => "rise" } } }
      expect(@dm.merge(hash_dst, hash_src)).to eq({ "property" => { "values" => { "are" => "stable", "can" => "change", "may" => "rise" } } })
    end

    it "should not modify the source or destination during the merge" do
      hash_dst = { "property" => %w{1 2 3} }
      hash_src = { "property" => %w{4 5 6} }
      ret = @dm.merge(hash_dst, hash_src)
      expect(hash_dst).to eq({ "property" => %w{1 2 3} })
      expect(hash_src).to eq({ "property" => %w{4 5 6} })
      expect(ret).to eq({ "property" => %w{1 2 3 4 5 6} })
    end

    it "should not error merging un-dupable objects" do
      @dm.deep_merge(nil, 4)
    end

  end

  describe "hash-only merging" do
    it "merges Hashes like normal deep merge" do
      merge_ee_hash = { "top_level_a" => { "1_deep_a" => "1-a-merge-ee", "1_deep_b" => "1-deep-b-merge-ee" }, "top_level_b" => "top-level-b-merge-ee" }
      merge_with_hash = { "top_level_a" => { "1_deep_b" => "1-deep-b-merged-onto", "1_deep_c" => "1-deep-c-merged-onto" }, "top_level_b" => "top-level-b-merged-onto" }

      merged_result = @dm.hash_only_merge(merge_ee_hash, merge_with_hash)

      expect(merged_result["top_level_b"]).to eq("top-level-b-merged-onto")
      expect(merged_result["top_level_a"]["1_deep_a"]).to eq("1-a-merge-ee")
      expect(merged_result["top_level_a"]["1_deep_b"]).to eq("1-deep-b-merged-onto")
      expect(merged_result["top_level_a"]["1_deep_c"]).to eq("1-deep-c-merged-onto")
    end

    it "replaces arrays rather than merging them" do
      merge_ee_hash = { "top_level_a" => { "1_deep_a" => "1-a-merge-ee", "1_deep_b" => %w{A A A} }, "top_level_b" => "top-level-b-merge-ee" }
      merge_with_hash = { "top_level_a" => { "1_deep_b" => %w{B B B}, "1_deep_c" => "1-deep-c-merged-onto" }, "top_level_b" => "top-level-b-merged-onto" }

      merged_result = @dm.hash_only_merge(merge_ee_hash, merge_with_hash)

      expect(merged_result["top_level_b"]).to eq("top-level-b-merged-onto")
      expect(merged_result["top_level_a"]["1_deep_a"]).to eq("1-a-merge-ee")
      expect(merged_result["top_level_a"]["1_deep_b"]).to eq(%w{B B B})
    end

    it "replaces non-hash items with hashes when there's a conflict" do
      merge_ee_hash = { "top_level_a" => "top-level-a-mergee", "top_level_b" => "top-level-b-merge-ee" }
      merge_with_hash = { "top_level_a" => { "1_deep_b" => %w{B B B}, "1_deep_c" => "1-deep-c-merged-onto" }, "top_level_b" => "top-level-b-merged-onto" }

      merged_result = @dm.hash_only_merge(merge_ee_hash, merge_with_hash)

      expect(merged_result["top_level_a"]).to be_a(Hash)
      expect(merged_result["top_level_a"]["1_deep_a"]).to be_nil
      expect(merged_result["top_level_a"]["1_deep_b"]).to eq(%w{B B B})
    end

    it "does not mutate deeply-nested original hashes by default" do
      merge_ee_hash =   { "top_level_a" => { "1_deep_a" => { "2_deep_a" => { "3_deep_a" => "foo" } } } }
      merge_with_hash = { "top_level_a" => { "1_deep_a" => { "2_deep_a" => { "3_deep_b" => "bar" } } } }
      @dm.hash_only_merge(merge_ee_hash, merge_with_hash)
      expect(merge_ee_hash).to eq({ "top_level_a" => { "1_deep_a" => { "2_deep_a" => { "3_deep_a" => "foo" } } } })
      expect(merge_with_hash).to eq({ "top_level_a" => { "1_deep_a" => { "2_deep_a" => { "3_deep_b" => "bar" } } } })
    end

    it "does not error merging un-dupable items" do
      merge_ee_hash = { "top_level_a" => 1, "top_level_b" => false }
      merge_with_hash = { "top_level_a" => 2, "top_level_b" => true }
      @dm.hash_only_merge(merge_ee_hash, merge_with_hash)
    end
  end
end
