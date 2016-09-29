#
# Copyright:: Copyright 2016, Chef Software Inc.
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
require "chef/node/attribute_collections"

describe Chef::Node::VividMash do
  class Root
    attr_accessor :top_level_breadcrumb
  end

  let(:root) { Root.new }

  let(:vivid) do
    expect(root).to receive(:reset_cache).at_least(:once).with(nil)
    Chef::Node::VividMash.new(
      { "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil },
      root
    )
  end

  def with_breadcrumb(key)
    expect(root).to receive(:top_level_breadcrumb=).with(nil).at_least(:once).and_call_original
    expect(root).to receive(:top_level_breadcrumb=).with(key).at_least(:once).and_call_original
  end

  context "#[]=" do
    it "deep converts values through arrays" do
      allow(root).to receive(:reset_cache)
      vivid[:foo] = [ { :bar => true } ]
      expect(vivid["foo"].class).to eql(Chef::Node::AttrArray)
      expect(vivid["foo"][0].class).to eql(Chef::Node::VividMash)
      expect(vivid["foo"][0]["bar"]).to be true
    end

    it "deep converts values through nested arrays" do
      allow(root).to receive(:reset_cache)
      vivid[:foo] = [ [ { :bar => true } ] ]
      expect(vivid["foo"].class).to eql(Chef::Node::AttrArray)
      expect(vivid["foo"][0].class).to eql(Chef::Node::AttrArray)
      expect(vivid["foo"][0][0].class).to eql(Chef::Node::VividMash)
      expect(vivid["foo"][0][0]["bar"]).to be true
    end

    it "deep converts values through hashes" do
      allow(root).to receive(:reset_cache)
      vivid[:foo] = { baz: { :bar => true } }
      expect(vivid["foo"]).to be_an_instance_of(Chef::Node::VividMash)
      expect(vivid["foo"]["baz"]).to be_an_instance_of(Chef::Node::VividMash)
      expect(vivid["foo"]["baz"]["bar"]).to be true
    end
  end

  context "#read" do
    before do
      # vivify the vividmash, then we're read-only so the cache should never be cleared afterwards
      vivid
      expect(root).not_to receive(:reset_cache)
    end

    it "reads hashes deeply" do
      with_breadcrumb("one")
      expect(vivid.read("one", "two", "three")).to eql("four")
    end

    it "does not trainwreck when hitting hash keys that do not exist" do
      with_breadcrumb("one")
      expect(vivid.read("one", "five", "six")).to eql(nil)
    end

    it "does not trainwreck when hitting an array with an out of bounds index" do
      with_breadcrumb("array")
      expect(vivid.read("array", 5, "one")).to eql(nil)
    end

    it "does not trainwreck when hitting an array with a string key" do
      with_breadcrumb("array")
      expect(vivid.read("array", "one", "two")).to eql(nil)
    end

    it "does not trainwreck when traversing a nil" do
      with_breadcrumb("nil")
      expect(vivid.read("nil", "one", "two")).to eql(nil)
    end
  end

  context "#exist?" do
    before do
      # vivify the vividmash, then we're read-only so the cache should never be cleared afterwards
      vivid
      expect(root).not_to receive(:reset_cache)
    end

    it "true if there's a hash key there" do
      with_breadcrumb("one")
      expect(vivid.exist?("one", "two", "three")).to be true
    end

    it "true for intermediate hashes" do
      with_breadcrumb("one")
      expect(vivid.exist?("one")).to be true
    end

    it "true for arrays that exist" do
      with_breadcrumb("array")
      expect(vivid.exist?("array", 1)).to be true
    end

    it "true when the value of the key is nil" do
      with_breadcrumb("nil")
      expect(vivid.exist?("nil")).to be true
    end

    it "false when attributes don't exist" do
      with_breadcrumb("one")
      expect(vivid.exist?("one", "five", "six")).to be false
    end

    it "false when traversing a non-container" do
      with_breadcrumb("one")
      expect(vivid.exist?("one", "two", "three", "four")).to be false
    end

    it "false when an array index does not exist" do
      with_breadcrumb("array")
      expect(vivid.exist?("array", 3)).to be false
    end

    it "false when traversing a nil" do
      with_breadcrumb("nil")
      expect(vivid.exist?("nil", "foo", "bar")).to be false
    end
  end

  context "#read!" do
    before do
      # vivify the vividmash, then we're read-only so the cache should never be cleared afterwards
      vivid
      expect(root).not_to receive(:reset_cache)
    end

    it "reads hashes deeply" do
      with_breadcrumb("one")
      expect(vivid.read!("one", "two", "three")).to eql("four")
    end

    it "reads arrays deeply" do
      with_breadcrumb("array")
      expect(vivid.read!("array", 1)).to eql(1)
    end

    it "throws an exception when attributes do not exist" do
      with_breadcrumb("one")
      expect { vivid.read!("one", "five", "six") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
    end

    it "throws an exception when traversing a non-container" do
      with_breadcrumb("one")
      expect { vivid.read!("one", "two", "three", "four") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
    end

    it "throws an exception when an array element does not exist" do
      with_breadcrumb("array")
      expect { vivid.read!("array", 3) }.to raise_error(Chef::Exceptions::NoSuchAttribute)
    end
  end

  context "#write" do
    before do
      vivid
      expect(root).not_to receive(:reset_cache).with(nil)
    end

    it "should write into hashes" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write("one", "five", "six")
      expect(vivid["one"]["five"]).to eql("six")
    end

    it "should deeply autovivify" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write("one", "five", "six", "seven", "eight", "nine", "ten")
      expect(vivid["one"]["five"]["six"]["seven"]["eight"]["nine"]).to eql("ten")
    end

    it "should raise an exception if you overwrite an array with a hash" do
      with_breadcrumb("array")
      expect(root).to receive(:reset_cache).at_least(:once).with("array")
      vivid.write("array", "five", "six")
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => { "five" => "six" }, "nil" => nil })
    end

    it "should raise an exception if you traverse through an array with a hash" do
      with_breadcrumb("array")
      expect(root).to receive(:reset_cache).at_least(:once).with("array")
      vivid.write("array", "five", "six", "seven")
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => { "five" => { "six" => "seven" } }, "nil" => nil })
    end

    it "should raise an exception if you overwrite a string with a hash" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write("one", "two", "three", "four", "five")
      expect(vivid).to eql({ "one" => { "two" => { "three" => { "four" => "five" } } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you traverse through a string with a hash" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write("one", "two", "three", "four", "five", "six")
      expect(vivid).to eql({ "one" => { "two" => { "three" => { "four" => { "five" => "six" } } } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you overwrite a nil with a hash" do
      with_breadcrumb("nil")
      expect(root).to receive(:reset_cache).at_least(:once).with("nil")
      vivid.write("nil", "one", "two")
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => { "one" => "two" } })
    end

    it "should raise an exception if you traverse through a nil with a hash" do
      with_breadcrumb("nil")
      expect(root).to receive(:reset_cache).at_least(:once).with("nil")
      vivid.write("nil", "one", "two", "three")
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => { "one" => { "two" => "three" } } })
    end

    it "writes with a block" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write("one", "five") { "six" }
      expect(vivid["one"]["five"]).to eql("six")
    end
  end

  context "#write!" do
    before do
      vivid
      expect(root).not_to receive(:reset_cache).with(nil)
    end

    it "should write into hashes" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write!("one", "five", "six")
      expect(vivid["one"]["five"]).to eql("six")
    end

    it "should deeply autovivify" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write!("one", "five", "six", "seven", "eight", "nine", "ten")
      expect(vivid["one"]["five"]["six"]["seven"]["eight"]["nine"]).to eql("ten")
    end

    it "should raise an exception if you overwrite an array with a hash" do
      with_breadcrumb("array")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("array", "five", "six") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you traverse through an array with a hash" do
      with_breadcrumb("array")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("array", "five", "six", "seven") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you overwrite a string with a hash" do
      with_breadcrumb("one")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("one", "two", "three", "four", "five") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you traverse through a string with a hash" do
      with_breadcrumb("one")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("one", "two", "three", "four", "five", "six") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you overwrite a nil with a hash" do
      with_breadcrumb("nil")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("nil", "one", "two") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should raise an exception if you traverse through a nil with a hash" do
      with_breadcrumb("nil")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.write!("nil", "one", "two", "three") }.to raise_error(Chef::Exceptions::AttributeTypeMismatch)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "writes with a block" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      vivid.write!("one", "five") { "six" }
      expect(vivid["one"]["five"]).to eql("six")
    end
  end

  context "#unlink" do
    before do
      vivid
      expect(root).not_to receive(:reset_cache).with(nil)
    end

    it "should return nil if the keys don't already exist" do
      expect(root).to receive(:top_level_breadcrumb=).with(nil).at_least(:once).and_call_original
      expect(root).not_to receive(:reset_cache)
      expect(vivid.unlink("five", "six", "seven", "eight")).to eql(nil)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should unlink hashes" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      expect( vivid.unlink("one") ).to eql({ "two" => { "three" => "four" } })
      expect(vivid).to eql({ "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should unlink array elements" do
      with_breadcrumb("array")
      expect(root).to receive(:reset_cache).at_least(:once).with("array")
      expect(vivid.unlink("array", 2)).to eql(2)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1 ], "nil" => nil })
    end

    it "should unlink nil" do
      with_breadcrumb("nil")
      expect(root).to receive(:reset_cache).at_least(:once).with("nil")
      expect(vivid.unlink("nil")).to eql(nil)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ] })
    end

    it "should traverse a nil and safely do nothing" do
      with_breadcrumb("nil")
      expect(root).not_to receive(:reset_cache)
      expect(vivid.unlink("nil", "foo")).to eql(nil)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end
  end

  context "#unlink!" do
    before do
      vivid
      expect(root).not_to receive(:reset_cache).with(nil)
    end

    it "should raise an exception if the keys don't already exist" do
      expect(root).to receive(:top_level_breadcrumb=).with(nil).at_least(:once).and_call_original
      expect(root).not_to receive(:reset_cache)
      expect { vivid.unlink!("five", "six", "seven", "eight") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should unlink! hashes" do
      with_breadcrumb("one")
      expect(root).to receive(:reset_cache).at_least(:once).with("one")
      expect( vivid.unlink!("one") ).to eql({ "two" => { "three" => "four" } })
      expect(vivid).to eql({ "array" => [ 0, 1, 2 ], "nil" => nil })
    end

    it "should unlink! array elements" do
      with_breadcrumb("array")
      expect(root).to receive(:reset_cache).at_least(:once).with("array")
      expect(vivid.unlink!("array", 2)).to eql(2)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1 ], "nil" => nil })
    end

    it "should unlink! nil" do
      with_breadcrumb("nil")
      expect(root).to receive(:reset_cache).at_least(:once).with("nil")
      expect(vivid.unlink!("nil")).to eql(nil)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ] })
    end

    it "should raise an exception if it traverses a nil" do
      with_breadcrumb("nil")
      expect(root).not_to receive(:reset_cache)
      expect { vivid.unlink!("nil", "foo") }.to raise_error(Chef::Exceptions::NoSuchAttribute)
      expect(vivid).to eql({ "one" => { "two" => { "three" => "four" } }, "array" => [ 0, 1, 2 ], "nil" => nil })
    end
  end
end
