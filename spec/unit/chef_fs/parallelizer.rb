require 'spec_helper'
require 'chef/chef_fs/parallelizer'

describe Chef::ChefFS::Parallelizer do
  # The amount of time between actions--this should be as small as possible, but
  # must be big enough that other processes aren't likely to lock up the server
  # for longer than that amount.
  #
  # Adjust this upwards if you are having timing problems on your platform.
  def delta
    0.1
  end

  # The length of time we spin waiting for something
  def epsilon
    0.05
  end

  before :each do
    @start_time = Time.now
  end

  def elapsed_time
    Time.now - @start_time
  end

  after :each do
    parallelizer.kill
  end

  context 'With a Parallelizer with 5 threads' do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(5)
    end

    def parallelize(inputs, options = {}, &block)
      parallelizer.parallelize(inputs, { :main_thread_processing => false }.merge(options), &block)
    end

    it "parallel_do creates unordered output as soon as it is available" do
      outputs = []
      parallelizer.parallel_do([5*delta,3*delta,1*delta]) do |val|
        sleep val
        outputs << val
      end
      elapsed_time.should < 6*delta
      outputs.should == [ 1*delta, 3*delta, 5*delta ]
    end

    context "With :ordered => false (unordered output)" do
      it "An empty input produces an empty output" do
        parallelize([], :ordered => false) do
          sleep 10
        end.to_a == []
        elapsed_time.should < 1*delta
      end

      it "10 sleep(2)s complete within 5 seconds" do
        parallelize(1.upto(10), :ordered => false) do |i|
          sleep 2*delta
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 5*delta
      end

      it "The output comes as soon as it is available" do
        enum = parallelize([5*delta,3*delta,1*delta], :ordered => false) do |val|
          sleep val
          val
        end
        enum.map do |value|
          elapsed_time.should < value+1*delta
          value
        end.should == [ 1*delta, 3*delta, 5*delta ]
      end

      it "An exception in input is passed through but does NOT stop processing" do
        input = TestEnumerable.new(5*delta,3*delta,1*delta) do
          raise 'hi'
        end
        enum = parallelize(input, :ordered => false) { |x| sleep(x); x }
        results = []
        expect { enum.each { |value| results << value } }.to raise_error 'hi'
        results.should == [ 1*delta, 3*delta, 5*delta ]
        elapsed_time.should < 6*delta
      end

      it "Exceptions in output are raised after all processing is done" do
        processed = 0
        enum = parallelize([1,2,'x',3], :ordered => false) do |x|
          if x == 'x'
            sleep 1*delta
            raise 'hi'
          end
          sleep 2*delta
          processed += 1
          x
        end
        results = []
        expect { enum.each { |value| results << value } }.to raise_error 'hi'
        results.sort.should == [ 1, 2, 3 ]
        elapsed_time.should < 3*delta
        processed.should == 3
      end

      it "Exceptions with :stop_on_exception are raised after all processing is done" do
        processed = 0
        parallelized = parallelize([3*delta,3*delta,'x',3*delta,3*delta,3*delta,3*delta,3*delta], :ordered => false, :stop_on_exception => true) do |x|
          if x == 'x'
            sleep(1*delta)
            raise 'hi'
          end
          sleep(x)
          processed += 1
          x
        end
        expect { parallelized.to_a }.to raise_error 'hi'
        processed.should == 4
      end
    end

    context "With :ordered => true (ordered output)" do
      it "An empty input produces an empty output" do
        parallelize([]) do
          sleep 10
        end.to_a == []
        elapsed_time.should < 1*delta
      end

      it "10 sleep(2*delta)s complete within 5*delta seconds" do
        parallelize(1.upto(10), :ordered => true) do |i|
          sleep 2*delta
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 5*delta
      end

      it "Output comes in the order of the input" do
        enum = parallelize([5*delta,3*delta,1*delta]) do |val|
          sleep val
          val
        end.enum_for(:each_with_index)
        enum.next.should == [ 5*delta, 0 ]
        enum.next.should == [ 3*delta, 1 ]
        enum.next.should == [ 1*delta, 2 ]
        elapsed_time.should < 6*delta
      end

      it "Exceptions in input are raised in the correct sequence but do NOT stop processing" do
        input = TestEnumerable.new(5*delta,3*delta,1*delta) do
          raise 'hi'
        end
        results = []
        enum = parallelize(input) { |x| sleep(x); x }
        expect { enum.each { |value| results << value } }.to raise_error 'hi'
        elapsed_time.should < 6*delta
        results.should == [ 5*delta, 3*delta, 1*delta ]
      end

      it "Exceptions in output are raised in the correct sequence and running processes do NOT stop processing" do
        processed = 0
        enum = parallelize([1,2,'x',3]) do |x|
          if x == 'x'
            sleep(1*delta)
            raise 'hi'
          end
          sleep(2*delta)
          processed += 1
          x
        end
        results = []
        expect { enum.each { |value| results << value } }.to raise_error 'hi'
        results.should == [ 1, 2 ]
        elapsed_time.should < 3*delta
        processed.should == 3
      end

      it "Exceptions with :stop_on_exception are raised after all processing is done" do
        processed = 0
        parallelized = parallelize([3*delta,3*delta,'x',3*delta,3*delta,3*delta,3*delta,3*delta], :ordered => false, :stop_on_exception => true) do |x|
          if x == 'x'
            sleep(1*delta)
            raise 'hi'
          end
          sleep(x)
          processed += 1
          x
        end
        expect { parallelized.to_a }.to raise_error 'hi'
        processed.should == 4
      end
    end

    it "When the input is slow, output still proceeds" do
      input = TestEnumerable.new do |&block|
        block.call(1)
        sleep 1*delta
        block.call(2)
        sleep 1*delta
        block.call(3)
        sleep 1*delta
      end
      enum = parallelize(input) { |x| x }
      enum.map do |value|
        elapsed_time.should < (value+1)*1*delta
        value
      end.should == [ 1, 2, 3 ]
    end
  end

  context "With a Parallelizer with 1 thread" do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(1)
    end

    context "when the thread is occupied with a job" do
      before :each do
        parallelizer
        started = false
        @occupying_job_finished = occupying_job_finished = [ false ]
        @thread = Thread.new do
          begin
            parallelizer.parallelize([0], :main_thread_processing => false) do |x|
              started = true
              sleep(3*delta)
              occupying_job_finished[0] = true
            end.wait
          ensure
          end
        end
        while !started
          sleep(epsilon)
        end
      end

      after :each do
        if RUBY_VERSION.to_f > 1.8
          Thread.kill(@thread)
        end
      end

      it "parallelize with :main_thread_processing = true does not block" do
        parallelizer.parallelize([1]) do |x|
          sleep(1*delta)
          x
        end.to_a.should == [ 1 ]
        elapsed_time.should < 2*delta
      end

      it "parallelize with :main_thread_processing = false waits for the job to finish" do
        parallelizer.parallelize([1], :main_thread_processing => false) do |x|
          sleep(1*delta)
          x+1
        end.to_a.should == [ 2 ]
        elapsed_time.should > 3*delta
      end

      it "resizing the Parallelizer to 0 waits for the job to stop" do
        elapsed_time.should < 2*delta
        parallelizer.resize(0)
        parallelizer.num_threads.should == 0
        elapsed_time.should > 2.5*delta
        @occupying_job_finished.should == [ true ]
      end

      it "stopping the Parallelizer waits for the job to finish" do
        elapsed_time.should < 2*delta
        parallelizer.stop
        parallelizer.num_threads.should == 0
        elapsed_time.should > 2.5*delta
        @occupying_job_finished.should == [ true ]
      end

      it "resizing the Parallelizer to 2 does not stop the job" do
        elapsed_time.should < 2*delta
        parallelizer.resize(2)
        parallelizer.num_threads.should == 2
        elapsed_time.should < 2*delta
        sleep(3*delta)
        @occupying_job_finished.should == [ true ]
      end
    end

    context "enumerable methods should run efficiently" do
      it ".count does not process anything" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3,4,5,6)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          sleep(epsilon) # Just enough to yield and get other inputs in the queue
          x
        end
        enum.count.should == 6
        outputs_processed.should == 0
        input_mapper.num_processed.should == 6
      end

      it ".count with arguments works normally" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,1,1,1,2,2,2,3,3,4)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          x
        end
        enum.count { |x| x > 1 }.should == 6
        enum.count(2).should == 3
        outputs_processed.should == 20
        input_mapper.num_processed.should == 20
      end

      it ".first does not enumerate anything other than the first result(s)" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3,4,5,6)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          sleep(epsilon) # Just enough to yield and get other inputs in the queue
          x
        end
        enum.first.should == 1
        enum.first(2).should == [1,2]
        outputs_processed.should == 3
        input_mapper.num_processed.should == 3
      end

      it ".take does not enumerate anything other than the first result(s)" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3,4,5,6)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          sleep(epsilon) # Just enough to yield and get other inputs in the queue
          x
        end
        enum.take(2).should == [1,2]
        outputs_processed.should == 2
        input_mapper.num_processed.should == 2
      end

      it ".drop does not process anything other than the last result(s)" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3,4,5,6)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          sleep(epsilon) # Just enough to yield and get other inputs in the queue
          x
        end
        enum.drop(2).should == [3,4,5,6]
        outputs_processed.should == 4
        input_mapper.num_processed.should == 6
      end

      if Enumerable.method_defined?(:lazy)
        it ".lazy.take does not enumerate anything other than the first result(s)" do
          outputs_processed = 0
          input_mapper = TestEnumerable.new(1,2,3,4,5,6)
          enum = parallelizer.parallelize(input_mapper) do |x|
            outputs_processed += 1
            sleep(epsilon) # Just enough to yield and get other inputs in the queue
            x
          end
          enum.lazy.take(2).to_a.should == [1,2]
          outputs_processed.should == 2
          input_mapper.num_processed.should == 2
        end

        it ".drop does not process anything other than the last result(s)" do
          outputs_processed = 0
          input_mapper = TestEnumerable.new(1,2,3,4,5,6)
          enum = parallelizer.parallelize(input_mapper) do |x|
            outputs_processed += 1
            sleep(epsilon) # Just enough to yield and get other inputs in the queue
            x
          end
          enum.lazy.drop(2).to_a.should == [3,4,5,6]
          outputs_processed.should == 4
          input_mapper.num_processed.should == 6
        end

        it "lazy enumerable is actually lazy" do
          outputs_processed = 0
          input_mapper = TestEnumerable.new(1,2,3,4,5,6)
          enum = parallelizer.parallelize(input_mapper) do |x|
            outputs_processed += 1
            sleep(epsilon) # Just enough to yield and get other inputs in the queue
            x
          end
          enum.lazy.take(2)
          enum.lazy.drop(2)
          sleep(1*delta)
          outputs_processed.should == 0
          input_mapper.num_processed.should == 0
        end
      end
    end

    context "running enumerable multiple times should function correctly" do
      it ".map twice on the same parallel enumerable returns the correct results and re-processes the input" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          x
        end
        enum.map { |x| x }.should == [1,2,3]
        enum.map { |x| x }.should == [1,2,3]
        outputs_processed.should == 6
        input_mapper.num_processed.should == 6
      end

      it ".first and then .map on the same parallel enumerable returns the correct results and re-processes the input" do
        outputs_processed = 0
        input_mapper = TestEnumerable.new(1,2,3)
        enum = parallelizer.parallelize(input_mapper) do |x|
          outputs_processed += 1
          x
        end
        enum.first.should == 1
        enum.map { |x| x }.should == [1,2,3]
        outputs_processed.should >= 4
        input_mapper.num_processed.should >= 4
      end

      it "two simultaneous enumerations throws an exception" do
        enum = parallelizer.parallelize([1,2,3]) { |x| x }
        a = enum.enum_for(:each)
        a.next
        expect do
          b = enum.enum_for(:each)
          b.next
        end.to raise_error
      end
    end
  end

  context "With a Parallelizer with 0 threads" do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(0)
    end

    context "And main_thread_processing on" do
      it "succeeds in running" do
        parallelizer.parallelize([5*delta]) { |x| x*2 }.to_a.should == [10*delta]
      end
    end
  end

  context "With a Parallelizer with 10 threads" do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(10)
    end

    it "does not have contention issues with large numbers of inputs" do
      parallelizer.parallelize(1.upto(500)) { |x| x+1 }.to_a.should == 2.upto(501).to_a
    end

    it "does not have contention issues with large numbers of inputs with ordering off" do
      parallelizer.parallelize(1.upto(500), :ordered => false) { |x| x+1 }.to_a.sort.should == 2.upto(501).to_a
    end

    it "does not have contention issues with large numbers of jobs and inputs with ordering off" do
      parallelizers = 0.upto(99).map do
        parallelizer.parallelize(1.upto(500)) { |x| x+1 }
      end
      outputs = []
      threads = 0.upto(99).map do |i|
        Thread.new { outputs[i] = parallelizers[i].to_a }
      end
      threads.each { |thread| thread.join }
      outputs.each { |output| output.sort.should == 2.upto(501).to_a }
    end
  end

  class TestEnumerable
    include Enumerable

    def initialize(*values, &block)
      @values = values
      @block = block
      @num_processed = 0
    end

    attr_reader :num_processed

    def each(&each_block)
      @values.each do |value|
        @num_processed += 1
        each_block.call(value)
      end
      if @block
        @block.call do |value|
          @num_processed += 1
          each_block.call(value)
        end
      end
    end
  end
end
