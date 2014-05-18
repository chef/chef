require 'thread'

class Chef
  module ChefFS
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

      class ParallelEnumerable
        include Enumerable

        # options:
        # :ordered [true|false] - whether the output should stay in the same order
        #   as the input (even though it may not actually be processed in that
        #   order). Default: true
        # :stop_on_exception [true|false] - if true, when an exception occurs in either
        #   input or output, we wait for any outstanding processing to complete,
        #   but will not process any new inputs. Default: false
        # :main_thread_processing [true|false] - whether the main thread pulling
        #   on each() is allowed to process inputs. Default: true
        #   NOTE: If you set this to false, parallelizer.kill will stop each()
        #   in its tracks, so you need to know for sure that won't happen.
        def initialize(parent_task_queue, enumerable, options, &block)
          @parent_task_queue = parent_task_queue
          @enumerable = enumerable
          @options = options
          @block = block

          @unconsumed_input = Queue.new
          @in_process = 0

          @unconsumed_output = Queue.new
        end

        def each
          each_with_input do |output, index, input, type|
            yield output
          end
        end

        def each_with_index
          each_with_input do |output, index, input|
            yield output, index
          end
        end

        def each_with_input
          exception = nil
          each_with_exceptions do |output, index, input, type|
            if type == :exception
              if @options[:ordered] == false
                exception ||= output
              else
                raise output
              end
            else
              yield output, index, input
            end
          end
          raise exception if exception
        end

        def each_with_exceptions(&block)
          if @options[:ordered] == false
            each_with_exceptions_unordered(&block)
          else
            each_with_exceptions_ordered(&block)
          end
        end

        def wait
          exception = nil
          each_with_exceptions_unordered do |output, index, input, type|
            exception ||= output if type == :exception
          end
          raise exception if exception
        end

        private

        def each_with_exceptions_unordered
          # Grab all the inputs, yielding any responses during enumeration
          # in case the enumeration itself takes time
          begin
            @enumerable.each_with_index do |input, index|
              @unconsumed_input.push([ input, index ])
              @parent_task_queue.push(method(:process_one))
              no_more_inputs = false
              while !@unconsumed_output.empty?
                output, index, input, type = @unconsumed_output.pop
                yield output, index, input, type
                if type == :exception && @options[:stop_on_exception]
                  no_more_inputs = true
                end
              end
              break if no_more_inputs
            end
          rescue
            # We still want to wait for the rest of the outputs to process
            @unconsumed_output.push([$!, nil, nil, :exception])
            if @options[:stop_on_exception]
              @unconsumed_input.clear
            end
          end

          while !@unconsumed_input.empty? || @in_process > 0 || !@unconsumed_output.empty?
            # yield thread to others (for 1.8.7)
            if @unconsumed_output.empty?
              sleep(0.01)
            end

            while !@unconsumed_output.empty?
              yield @unconsumed_output.pop
            end

            # If no one is working on our tasks and we're allowed to
            # work on them in the main thread, process an input to
            # move things forward.
            if @in_process == 0 && !(@options[:main_thread_processing] == false)
              process_one
            end
          end
        end

        def each_with_exceptions_ordered
          next_to_yield = 0
          unconsumed = {}
          each_with_exceptions_unordered do |output, index, input, type|
            unconsumed[index] = [ output, input, type ]
            while unconsumed[next_to_yield]
              input_output = unconsumed.delete(next_to_yield)
              yield input_output[0], next_to_yield, input_output[1], input_output[2]
              next_to_yield += 1
            end
          end
          input_exception = unconsumed.delete(nil)
          if input_exception
            yield input_exception[0], next_to_yield, input_exception[1], input_exception[2]
          end
        end

        def process_one
          @in_process += 1
          begin
            begin
              input, index = @unconsumed_input.pop(true)
              process_input(input, index)
            rescue ThreadError
            end
          ensure
            @in_process -= 1
          end
        end

        def process_input(input, index)
          begin
            output = @block.call(input)
            @unconsumed_output.push([ output, index, input, :result ])
          rescue
            if @options[:stop_on_exception]
              @unconsumed_input.clear
            end
            @unconsumed_output.push([ $!, index, input, :exception ])
          end

          index
        end
      end
    end
  end
end
