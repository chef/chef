#
# Author:: Matthew Kent (<mkent@magoazul.com>)
# Copyright:: Copyright 2011-2016, Chef Software Inc.
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
require "chef/mash"

describe Mash do
  it "should duplicate a simple key/value mash to a new mash" do
    data = { :x => "one", :y => "two", :z => "three" }
    @orig = Mash.new(data)
    @copy = @orig.dup
    expect(@copy.to_hash).to eq(Mash.new(data).to_hash)
    @copy[:x] = "four"
    expect(@orig[:x]).to eq("one")
  end

  it "should duplicate a mash with an array to a new mash" do
    data = { :x => "one", :y => "two", :z => [1, 2, 3] }
    @orig = Mash.new(data)
    @copy = @orig.dup
    expect(@copy.to_hash).to eq(Mash.new(data).to_hash)
    @copy[:z] << 4
    expect(@orig[:z]).to eq([1, 2, 3])
  end

  it "should duplicate a nested mash to a new mash" do
    data = { :x => "one", :y => "two", :z => Mash.new({ :a => [1, 2, 3] }) }
    @orig = Mash.new(data)
    @copy = @orig.dup
    expect(@copy.to_hash).to eq(Mash.new(data).to_hash)
    @copy[:z][:a] << 4
    expect(@orig[:z][:a]).to eq([1, 2, 3])
  end

  # add more!
end
