# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require "chef-utils/parallel_map"

using ChefUtils::ParallelMap

RSpec.describe ChefUtils::ParallelMap do

  shared_examples_for "common parallel API tests" do

    before(:each) do
      ChefUtils::DefaultThreadPool.instance.instance_variable_set(:@pool, nil)
      ChefUtils::DefaultThreadPool.instance.threads = threads
    end

    after(:each) do
      ChefUtils::DefaultThreadPool.instance.instance_variable_set(:@pool, nil)
    end

    it "parallel_map runs in parallel" do
      # this is implicitly also testing that we run in the caller when we exhaust threads by running threads+1
      val = threads + 1
      ret = []
      start = Time.now
      (1..val).parallel_map do |i|
        loop do
          if val == i
            ret << i
            val -= 1
            break
          end
          # we spin for quite awhile to wait for very slow testers if we have to
          if Time.now - start > 30
            raise "timed out; deadlocked due to lack of parallelization?"
          end

          # need to sleep a tiny bit to let other threads schedule
          sleep 0.000001
        end
      end
      expected = (1..threads + 1).to_a.reverse
      expect(ret).to eql(expected)
    end

    it "parallel_each runs in parallel" do
      # this is implicitly also testing that we run in the caller when we exhaust threads by running threads+1
      val = threads + 1
      ret = []
      start = Time.now
      (1..val).parallel_each do |i|
        loop do
          if val == i
            ret << i
            val -= 1
            break
          end
          # we spin for quite awhile to wait for very slow testers if we have to
          if Time.now - start > 30
            raise "timed out; deadlocked due to lack of parallelization?"
          end

          # need to sleep a tiny bit to let other threads schedule
          sleep 0.000001
        end
      end
      expected = (1..threads + 1).to_a.reverse
      expect(ret).to eql(expected)
    end

    it "parallel_map throws exceptions" do
      expect { (0..10).parallel_map { |i| raise "boom" } }.to raise_error(RuntimeError)
    end

    it "parallel_each throws exceptions" do
      expect { (0..10).parallel_each { |i| raise "boom" } }.to raise_error(RuntimeError)
    end

    it "parallel_map runs" do
      ans = Timeout.timeout(30) do
        (1..10).parallel_map { |i| i }
      end
      expect(ans).to eql((1..10).to_a)
    end

    it "parallel_each runs" do
      Timeout.timeout(30) do
        (1..10).parallel_each { |i| i }
      end
    end

    it "recursive parallel_map will not deadlock" do
      ans = Timeout.timeout(30) do
        (1..2).parallel_map { |i| (1..2).parallel_map { |i| i } }
      end
      expect(ans).to eql([[1, 2], [1, 2]])
    end

    it "recursive parallel_each will not deadlock" do
      Timeout.timeout(30) do
        (1..2).parallel_each { |i| (1..2).parallel_each { |i| i } }
      end
    end

    it "parallel_map is lazy" do
      ans = Timeout.timeout(30) do
        (1..).lazy.parallel_map { |i| i }.first(5)
      end
      expect(ans).to eql((1..5).to_a)
    end

    it "parallel_each is lazy" do
      Timeout.timeout(30) do
        (1..).lazy.parallel_each { |i| i }.first(5)
      end
    end
  end

  context "with 10 threads" do
    let(:threads) { 10 }
    it_behaves_like "common parallel API tests"
  end

  context "with 0 threads" do
    let(:threads) { 0 }
    it_behaves_like "common parallel API tests"
  end

  context "with 1 threads" do
    let(:threads) { 1 }
    it_behaves_like "common parallel API tests"
  end

  context "flat_each" do
    it "runs each over items which are nested one level" do
      sum = 0
      [ [ 1, 2 ], [3, 4]].flat_each { |i| sum += i }
      expect(sum).to eql(10)
    end
  end
end
