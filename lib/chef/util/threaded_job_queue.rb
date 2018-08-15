# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

require "thread"

class Chef
  class Util
    # A simple threaded job queue
    #
    # Create a queue:
    #
    #     queue = ThreadedJobQueue.new
    #
    # Add jobs:
    #
    #     queue << lambda { |lock| foo.the_bar }
    #
    # A job is a callable that optionally takes a Mutex instance as its only
    # parameter.
    #
    # Then start processing jobs with +n+ threads:
    #
    #     queue.process(n)
    #
    class ThreadedJobQueue
      def initialize
        @queue = Queue.new
        @lock = Mutex.new
      end

      def <<(job)
        @queue << job
      end

      def process(concurrency = 10)
        workers = (1..concurrency).map do
          Thread.new do
            loop do
              fn = @queue.pop
              fn.arity == 1 ? fn.call(@lock) : fn.call
            end
          end
        end
        workers.each { |worker| self << Thread.method(:exit) }
        workers.each { |worker| worker.join }
      end
    end
  end
end
