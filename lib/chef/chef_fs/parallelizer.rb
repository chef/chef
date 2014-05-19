require 'thread'
require 'chef/chef_fs/parallelizer/parallel_enumerable'

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
        if @@threads != value
          @@threads = value
          @@parallelizer.kill
          @@parallelizer = nil
        end
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

      def initialize(threads)
        @tasks = Queue.new
        @threads = []
        1.upto(threads) do |i|
          @threads << Thread.new(&method(:worker_loop))
        end
      end

      def parallelize(enumerable, options = {}, &block)
        ParallelEnumerable.new(@tasks, enumerable, options, &block)
      end

      def parallel_do(enumerable, options = {}, &block)
        ParallelEnumerable.new(@tasks, enumerable, options.merge(:ordered => false), &block).wait
      end

      def kill
        @threads.each do |thread|
          Thread.kill(thread)
        end
        @threads = []
      end

      private

      def worker_loop
        while true
          begin
            task = @tasks.pop
            task.call
          rescue
            puts "ERROR #{$!}"
            puts $!.backtrace
          end
        end
      end
    end
  end
end
