class Chef
  module ChefFS
    class Parallelizer
      @@parallelizer = nil
      @@threads = 0

      def self.threads=(value)
        if @@threads != value
          @@threads = value
          @@parallelizer = nil
        end
      end

      def self.parallelize(enumerator, options = {}, &block)
        @@parallelizer ||= Parallelizer.new(@@threads)
        @@parallelizer.parallelize(enumerator, options, &block)
      end

      def initialize(threads)
        @tasks_mutex = Mutex.new
        @tasks = []
        @threads = []
        1.upto(threads) do
          @threads << Thread.new { worker_loop }
        end
      end

      def parallelize(enumerator, options = {}, &block)
        task = ParallelizedResults.new(enumerator, options, &block)
        @tasks_mutex.synchronize do
          @tasks << task
        end
        task
      end

      class ParallelizedResults
        include Enumerable

        def initialize(enumerator, options, &block)
          @inputs = enumerator.to_a
          @options = options
          @block = block

          @mutex = Mutex.new
          @outputs = []
          @status = []
        end

        def each
          next_index = 0
          while true
            # Report any results that already exist
            while @status.length > next_index && ([:finished, :exception].include?(@status[next_index]))
              if @status[next_index] == :finished
                if @options[:flatten]
                  @outputs[next_index].each do |entry|
                    yield entry
                  end
                else
                  yield @outputs[next_index]
                end
              else
                raise @outputs[next_index]
              end
              next_index = next_index + 1
            end

            # Pick up a result and process it, if there is one.  This ensures we
            # move forward even if there are *zero* worker threads available.
            if !process_input
              # Exit if we're done.
              if next_index >= @status.length
                break
              else
                # Ruby 1.8 threading sucks.  Wait till we process more things.
                sleep(0.05)
              end
            end
          end
        end

        def process_input
          # Grab the next one to process
          index, input = @mutex.synchronize do
            index = @status.length
            if index >= @inputs.length
              return nil
            end
            input = @inputs[index]
            @status[index] = :started
            [ index, input ]
          end

          begin
            @outputs[index] = @block.call(input)
            @status[index] = :finished
          rescue Exception
            @outputs[index] = $!
            @status[index] = :exception
          end
          index
        end
      end

      private

      def worker_loop
        while true
          begin
            task = @tasks[0]
            if task
              if !task.process_input
                @tasks_mutex.synchronize do
                  @tasks.delete(task)
                end
              end
            else
              # Ruby 1.8 threading sucks.  Wait a bit to see if another task comes in.
              sleep(0.05)
            end
          rescue
            puts "ERROR #{$!}"
            puts $!.backtrace
          end
        end
      end
    end
  end
end
