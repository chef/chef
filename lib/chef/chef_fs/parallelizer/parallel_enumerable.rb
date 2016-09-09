require "chef/chef_fs/parallelizer/flatten_enumerable"

class Chef
  module ChefFS
    class Parallelizer
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
        def initialize(parent_task_queue, input_enumerable, options = {}, &block)
          @parent_task_queue = parent_task_queue
          @input_enumerable = input_enumerable
          @options = options
          @block = block

          @unconsumed_input = Queue.new
          @in_process = {}
          @unconsumed_output = Queue.new
        end

        attr_reader :parent_task_queue
        attr_reader :input_enumerable
        attr_reader :options
        attr_reader :block

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

        # Enumerable methods
        def restricted_copy(enumerable)
          ParallelEnumerable.new(@parent_task_queue, enumerable, @options, &@block)
        end

        alias :original_count :count

        def count(*args, &block)
          if args.size == 0 && block.nil?
            @input_enumerable.count
          else
            original_count(*args, &block)
          end
        end

        def first(n = nil)
          if n
            restricted_copy(@input_enumerable.first(n)).to_a
          else
            first(1)[0]
          end
        end

        def drop(n)
          restricted_copy(@input_enumerable.drop(n)).to_a
        end

        def flatten(levels = nil)
          FlattenEnumerable.new(self, levels)
        end

        def take(n)
          restricted_copy(@input_enumerable.take(n)).to_a
        end

        if Enumerable.method_defined?(:lazy)
          class RestrictedLazy
            def initialize(parallel_enumerable, actual_lazy)
              @parallel_enumerable = parallel_enumerable
              @actual_lazy = actual_lazy
            end

            def drop(*args, &block)
              input = @parallel_enumerable.input_enumerable.lazy.drop(*args, &block)
              @parallel_enumerable.restricted_copy(input)
            end

            def take(*args, &block)
              input = @parallel_enumerable.input_enumerable.lazy.take(*args, &block)
              @parallel_enumerable.restricted_copy(input)
            end

            def method_missing(method, *args, &block)
              @actual_lazy.send(:method, *args, &block)
            end
          end

          alias :original_lazy :lazy

          def lazy
            RestrictedLazy.new(self, original_lazy)
          end
        end

        private

        def each_with_exceptions_unordered
          if @each_running
            raise "each() called on parallel enumerable twice simultaneously!  Bad mojo"
          end
          @each_running = true
          begin
            # Grab all the inputs, yielding any responses during enumeration
            # in case the enumeration itself takes time
            begin
              @input_enumerable.each_with_index do |input, index|
                @unconsumed_input.push([ input, index ])
                @parent_task_queue.push(method(:process_one))

                stop_processing_input = false
                until @unconsumed_output.empty?
                  output, index, input, type = @unconsumed_output.pop
                  yield output, index, input, type
                  if type == :exception && @options[:stop_on_exception]
                    stop_processing_input = true
                    break
                  end
                end

                if stop_processing_input
                  break
                end
              end
            rescue
              # We still want to wait for the rest of the outputs to process
              @unconsumed_output.push([$!, nil, nil, :exception])
              if @options[:stop_on_exception]
                @unconsumed_input.clear
              end
            end

            until finished?
              # yield thread to others (for 1.8.7)
              if @unconsumed_output.empty?
                sleep(0.01)
              end

              yield @unconsumed_output.pop until @unconsumed_output.empty?

              # If no one is working on our tasks and we're allowed to
              # work on them in the main thread, process an input to
              # move things forward.
              if @in_process.size == 0 && !(@options[:main_thread_processing] == false)
                process_one
              end
            end
          rescue
            # If we exited early, perhaps due to any? finding a result, we want
            # to make sure and throw away any extra results (gracefully) so that
            # the next enumerator can start over.
            if !finished?
              stop
            end
            raise
          ensure
            @each_running = false
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

        def stop
          @unconsumed_input.clear
          sleep(0.05) while @in_process.size > 0
          @unconsumed_output.clear
        end

        #
        # This is thread safe only if called from the main thread pulling on each().
        # The order of these checks is important, as well, to be thread safe.
        # 1. If @unconsumed_input.empty? is true, then we will never have any more
        # work legitimately picked up.
        # 2. If @in_process == 0, then there is no work in process, and because ofwhen unconsumed_input is empty, it will never go back up, because
        # this is called after the input enumerator is finished.  Note that switching #2 and #1
        # could cause a race, because in_process is incremented *before* consuming input.
        # 3. If @unconsumed_output.empty? is true, then we are done with outputs.
        # Thus, 1+2 means no more output will ever show up, and 3 means we've passed all
        # existing outputs to the user.
        #
        def finished?
          @unconsumed_input.empty? && @in_process.size == 0 && @unconsumed_output.empty?
        end

        def process_one
          @in_process[Thread.current] = true
          begin
            begin
              input, index = @unconsumed_input.pop(true)
              process_input(input, index)
            rescue ThreadError
            end
          ensure
            @in_process.delete(Thread.current)
          end
        end

        def process_input(input, index)
          begin
            output = @block.call(input)
            @unconsumed_output.push([ output, index, input, :result ])
          rescue StandardError, ScriptError
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
