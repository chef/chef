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

require "concurrent/executors"
require "concurrent/future"
require "singleton" unless defined?(Singleton)

module ChefUtils
  #
  # This module contains ruby refinements that adds several methods to the Enumerable
  # class which are useful for parallel processing.
  #
  module ParallelMap
    refine Enumerable do

      # Enumerates through the collection in parallel using the thread pool provided
      # or the default thread pool.  By using the default thread pool this supports
      # recursively calling the method without deadlocking while using a globally
      # fixed number of workers.  This method supports lazy collections.  It returns
      # synchronously, waiting until all the work is done.  Failures are only reported
      # after the collection has executed and only the first exception is raised.
      #
      # (0..).lazy.parallel_map { |i| i*i }.first(5)
      #
      # @return [Array] output results
      #
      def parallel_map(pool: nil)
        return self unless block_given?

        pool ||= ChefUtils::DefaultThreadPool.instance.pool

        futures = map do |item|
          Concurrent::Future.execute(executor: pool) do
            yield item
          end
        end

        futures.map(&:value!)
      end

      # This has the same behavior as parallel_map but returns the enumerator instead of
      # the return values.
      #
      # @return [Enumerable] the enumerable for method chaining
      #
      def parallel_each(pool: nil, &block)
        return self unless block_given?

        parallel_map(pool: pool, &block)

        self
      end

      # The flat_each method is tightly coupled to the usage of parallel_map within the
      # ChefFS implementation.  It is not itself a parallel method, but it is used to
      # iterate through the 2nd level of nested structure, which is tied to the nested
      # structures that ChefFS returns.
      #
      # This is different from Enumerable#flat_map because that behaves like map.flatten(1) while
      # this behaves more like flatten(1).each.  We need this on an Enumerable, so we have no
      # Enumerable#flatten method to call.
      #
      # [ [ 1, 2 ], [ 3, 4 ] ].flat_each(&block) calls block four times with 1, 2, 3, 4
      #
      # [ [ 1, 2 ], [ 3, 4 ] ].flat_map(&block) calls block twice with [1, 2] and [3,4]
      #
      def flat_each(&block)
        map do |value|
          if value.is_a?(Enumerable)
            value.each(&block)
          else
            yield value
          end
        end
      end
    end
  end

  # The DefaultThreadPool has a fixed thread size and has no
  # queue of work and the behavior on failure to find a thread is for the
  # caller to run the work.  This contract means that the thread pool can
  # be called recursively without deadlocking and while keeping the fixed
  # number of threads (and not exponentially growing the thread pool with
  # the depth of recursion).
  #
  class DefaultThreadPool
    include Singleton

    DEFAULT_THREAD_SIZE = 10

    # Size of the thread pool, must be set before getting the thread pool or
    # calling parallel_map/parallel_each.  Does not (but could be modified to)
    # support dynamic resizing. To get fully synchronous behavior set this equal to
    # zero rather than one since the caller will get work if the threads are
    # busy.
    #
    # @return [Integer] number of threads
    attr_accessor :threads

    # Memoizing accessor for the thread pool
    #
    # @return [Concurrent::ThreadPoolExecutor] the thread pool
    def pool
      @pool ||= Concurrent::ThreadPoolExecutor.new(
        min_threads: threads || DEFAULT_THREAD_SIZE,
        max_threads: threads || DEFAULT_THREAD_SIZE,
        max_queue: 0,
        # "synchronous" redefines the 0 in max_queue to mean 'no queue' instead of 'infinite queue'
        # it does not mean synchronous execution (no threads) but synchronous offload to the threads.
        synchronous: true,
        # this prevents deadlocks on recursive parallel usage
        fallback_policy: :caller_runs
      )
    end
  end
end
