require "thread"
require "chef/chef_fs/parallelizer/parallel_enumerable"

class Chef
  module ChefFS
    # Tries to balance several guarantees, in order of priority:
    # - don't get deadlocked
    # - provide results in desired order
    # - provide results as soon as they are available
    # - process input as soon as possible
    class Parallelizer
      @@parallelizer = nil
      @@threads = 0

      def self.threads=(value)
        @@threads = value
        @@parallelizer.resize(value) if @@parallelizer
      end

      def self.parallelizer
        @@parallelizer ||= Parallelizer.new(@@threads)
      end

      def self.parallelize(enumerable, options = {}, &block)
        parallelizer.parallelize(enumerable, options, &block)
      end

      def self.parallel_do(enumerable, options = {}, &block)
        parallelizer.parallel_do(enumerable, options, &block)
      end

      def initialize(num_threads)
        @tasks = Queue.new
        @threads = []
        @stop_thread = {}
        resize(num_threads)
      end

      def num_threads
        @threads.size
      end

      def parallelize(enumerable, options = {}, &block)
        ParallelEnumerable.new(@tasks, enumerable, options, &block)
      end

      def parallel_do(enumerable, options = {}, &block)
        ParallelEnumerable.new(@tasks, enumerable, options.merge(:ordered => false), &block).wait
      end

      def stop(wait = true, timeout = nil)
        resize(0, wait, timeout)
      end

      def resize(to_threads, wait = true, timeout = nil)
        if to_threads < num_threads
          threads_to_stop = @threads[to_threads..num_threads - 1]
          @threads = @threads.slice(0, to_threads)
          threads_to_stop.each do |thread|
            @stop_thread[thread] = true
          end

          if wait
            start_time = Time.now
            threads_to_stop.each do |thread|
              thread_timeout = timeout ? timeout - (Time.now - start_time) : nil
              thread.join(thread_timeout)
            end
          end

        else
          num_threads.upto(to_threads - 1) do |i|
            @threads[i] = Thread.new(&method(:worker_loop))
          end
        end
      end

      def kill
        @threads.each do |thread|
          Thread.kill(thread)
          @stop_thread.delete(thread)
        end
        @threads = []
      end

      private

      def worker_loop
        until @stop_thread[Thread.current]
          begin
            task = @tasks.pop
            task.call
          rescue
            puts "ERROR #{$!}"
            puts $!.backtrace
          end
        end
      ensure
        @stop_thread.delete(Thread.current)
      end
    end
  end
end
