# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright 2009-2016, Daniel DeLeo
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

describe Chef::ResourceCollection::StepableIterator do
  CRSI = Chef::ResourceCollection::StepableIterator

  it "has an empty array for its collection by default" do
    expect(CRSI.new.collection).to eq([])
  end

  describe "doing basic iteration" do
    before do
      @simple_collection = [1, 2, 3, 4]
      @iterator = CRSI.for_collection(@simple_collection)
    end

    it "re-initializes the instance with a collection" do
      expect(@iterator.collection).to equal(@simple_collection)
      expect(@iterator.size).to eq(4)
    end

    it "iterates over the collection" do
      sum = 0
      @iterator.each do |int|
        sum += int
      end
      expect(sum).to eq(10)
    end

    it "iterates over the collection with each_index" do
      collected_by_index = []
      @iterator.each_index do |idx|
        collected_by_index << @simple_collection[idx]
      end
      expect(collected_by_index).to eq(@simple_collection)
      expect(collected_by_index).not_to equal(@simple_collection)
    end

    it "iterates over the collection with index and element" do
      collected = {}
      @iterator.each_with_index do |element, index|
        collected[index] = element
      end
      expect(collected).to eq({ 0 => 1, 1 => 2, 2 => 3, 3 => 4 })
    end

  end

  describe "pausing and resuming iteration" do

    before do
      @collection = []
      @snitch_var = nil
      @collection << lambda { @snitch_var = 23 }
      @collection << lambda { @iterator.pause }
      @collection << lambda { @snitch_var = 42 }

      @iterator = CRSI.for_collection(@collection)
      @iterator.each { |proc| proc.call }
    end

    it "allows the iteration to be paused" do
      expect(@snitch_var).to eq(23)
    end

    it "allows the iteration to be resumed" do
      expect(@snitch_var).to eq(23)
      @iterator.resume
      expect(@snitch_var).to eq(42)
    end

    it "allows iteration to be rewound" do
      @iterator.skip_back(2)
      @iterator.resume
      expect(@snitch_var).to eq(23)
      @iterator.resume
      expect(@snitch_var).to eq(42)
    end

    it "allows iteration to be fast forwarded" do
      @iterator.skip_forward
      @iterator.resume
      expect(@snitch_var).to eq(23)
    end

    it "allows iteration to be rewound" do
      @snitch_var = nil
      @iterator.rewind
      expect(@iterator.position).to eq(0)
      @iterator.resume
      expect(@snitch_var).to eq(23)
    end

    it "allows iteration to be stepped" do
      @snitch_var = nil
      @iterator.rewind
      @iterator.step
      expect(@iterator.position).to eq(1)
      expect(@snitch_var).to eq(23)
    end

    it "doesn't step if there are no more steps" do
      expect(@iterator.step).to eq(3)
      expect { @iterator.step }.not_to raise_error
      expect(@iterator.step).to be_nil
    end

    it "allows the iteration to start by being stepped" do
      @snitch_var = nil
      @iterator = CRSI.for_collection(@collection)
      @iterator.iterate_on(:element) { |proc| proc.call }
      @iterator.step
      expect(@iterator.position).to eq(1)
      expect(@snitch_var).to eq(23)
    end

    it "should work correctly when elements are added to the collection during iteration" do
      @collection.insert(2, lambda { @snitch_var = 815 })
      @collection.insert(3, lambda { @iterator.pause })
      @iterator.resume
      expect(@snitch_var).to eq(815)
      @iterator.resume
      expect(@snitch_var).to eq(42)
    end

  end

end
