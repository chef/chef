require 'spec_helper'
require 'chef/chef_fs/parallelizer'

describe Chef::ChefFS::Parallelizer do
  class EnumerableWithException
    include Enumerable

    def initialize(*results)
      @results = results
    end

    def each
      @results.each do |x|
        yield x
      end
      raise 'hi'
    end
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
      parallelizer.parallel_do([0.5,0.3,0.1]) do |val|
        sleep val
        outputs << val
      end
      elapsed_time.should < 0.6
      outputs.should == [ 0.1, 0.3, 0.5 ]
    end

    context "With :ordered => false (unordered output)" do
      it "An empty input produces an empty output" do
        parallelize([], :ordered => false) do
          sleep 10
        end.to_a == []
        elapsed_time.should < 0.1
      end

      it "10 sleep(0.2)s complete within 0.5 seconds" do
        parallelize(1.upto(10), :ordered => false) do |i|
          sleep 0.2
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 0.5
      end

      it "The output comes as soon as it is available" do
        enum = parallelize([0.5,0.3,0.1], :ordered => false) do |val|
          sleep val
          val
        end.enum_for(:each_with_index)
        enum.next.should == [ 0.1, 2 ]
        elapsed_time.should < 0.2
        enum.next.should == [ 0.3, 1 ]
        elapsed_time.should < 0.4
        enum.next.should == [ 0.5, 0 ]
        elapsed_time.should < 0.6
      end

      it "An exception in input is passed through but does NOT stop processing" do
        enum = parallelize(EnumerableWithException.new(0.5,0.3,0.1), :ordered => false) { |x| sleep(x); x }.enum_for(:each)
        enum.next.should == 0.1
        enum.next.should == 0.3
        enum.next.should == 0.5
        expect { enum.next }.to raise_error 'hi'
        elapsed_time.should < 0.6
      end

      it "Exceptions in output are raised after all processing is done" do
        processed = 0
        enum = parallelize([0.2,0.1,'x',0.3], :ordered => false) do |x|
          sleep(x)
          processed += 1
          x
        end.enum_for(:each)
        enum.next.should == 0.1
        enum.next.should == 0.2
        elapsed_time.should < 0.3
        enum.next.should == 0.3
        expect { enum.next }.to raise_error
        elapsed_time.should < 0.4
        processed.should == 3
      end

      it "Exceptions with :stop_on_exception are raised after all processing is done" do
        processed = 0
        parallelized = parallelize([0.3,0.3,'x',0.3,0.3,0.3,0.3,0.3], :ordered => false, :stop_on_exception => true) do |x|
          if x == 'x'
            sleep(0.1)
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
        elapsed_time.should < 0.1
      end

      it "10 sleep(0.2)s complete within 0.5 seconds" do
        parallelize(1.upto(10), :ordered => true) do |i|
          sleep 0.2
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 0.5
      end

      it "Output comes in the order of the input" do
        enum = parallelize([0.5,0.3,0.1]) do |val|
          sleep val
          val
        end.enum_for(:each_with_index)
        enum.next.should == [ 0.5, 0 ]
        enum.next.should == [ 0.3, 1 ]
        enum.next.should == [ 0.1, 2 ]
        elapsed_time.should < 0.6
      end

      it "Exceptions in input are raised in the correct sequence but do NOT stop processing" do
        enum = parallelize(EnumerableWithException.new(0.5,0.3,0.1)) { |x| sleep(x); x }.enum_for(:each)
        enum.next.should == 0.5
        elapsed_time.should < 0.7
        enum.next.should == 0.3
        enum.next.should == 0.1
        expect { enum.next }.to raise_error 'hi'
        elapsed_time.should < 0.7
      end

      it "Exceptions in output are raised in the correct sequence and running processes do NOT stop processing" do
        processed = 0
        enum = parallelize([0.2,0.1,'x',0.3]) do |x|
          if x == 'x'
            while processed < 3
              sleep(0.05)
            end
            raise 'hi'
          end
          sleep(x)
          processed += 1
          x
        end.enum_for(:each)
        enum.next.should == 0.2
        enum.next.should == 0.1
        expect { enum.next }.to raise_error 'hi'
        elapsed_time.should > 0.25
        elapsed_time.should < 0.55
        processed.should == 3
      end

      it "Exceptions with :stop_on_exception are raised after all processing is done" do
        processed = 0
        parallelized = parallelize([0.3,0.3,'x',0.3,0.3,0.3,0.3,0.3], :ordered => false, :stop_on_exception => true) do |x|
          if x == 'x'
            sleep(0.1)
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

    class SlowEnumerable
      def initialize(*values)
        @values = values
      end
      include Enumerable
      def each
        @values.each do |value|
          yield value
          sleep 0.1
        end
      end
    end

    it "When the input is slow, output still proceeds" do
      enum = parallelize(SlowEnumerable.new(1,2,3)) { |x| x }.enum_for(:each)
      enum.next.should == 1
      elapsed_time.should < 0.2
      enum.next.should == 2
      elapsed_time.should < 0.3
      enum.next.should == 3
      elapsed_time.should < 0.4
      expect { enum.next }.to raise_error StopIteration
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
          parallelizer.parallelize([0], :main_thread_processing => false) do |x|
            started = true
            sleep(0.3)
            occupying_job_finished[0] = true
          end.wait
        end
        while !started
          sleep(0.01)
        end
      end

      after :each do
        Thread.kill(@thread)
      end

      it "parallelize with :main_thread_processing = true does not block" do
        parallelizer.parallelize([1]) do |x|
          sleep(0.1)
          x
        end.to_a.should == [ 1 ]
        elapsed_time.should < 0.2
      end

      it "parallelize with :main_thread_processing = false waits for the job to finish" do
        parallelizer.parallelize([1], :main_thread_processing => false) do |x|
          sleep(0.1)
          x+1
        end.to_a.should == [ 2 ]
        elapsed_time.should > 0.3
      end

      it "resizing the Parallelizer to 0 waits for the job to stop" do
        elapsed_time.should < 0.2
        parallelizer.resize(0)
        parallelizer.num_threads.should == 0
        elapsed_time.should > 0.25
        @occupying_job_finished.should == [ true ]
      end

      it "stopping the Parallelizer waits for the job to finish" do
        elapsed_time.should < 0.2
        parallelizer.stop
        parallelizer.num_threads.should == 0
        elapsed_time.should > 0.25
        @occupying_job_finished.should == [ true ]
      end

      it "resizing the Parallelizer to 2 does not stop the job" do
        elapsed_time.should < 0.2
        parallelizer.resize(2)
        parallelizer.num_threads.should == 2
        elapsed_time.should < 0.2
        sleep(0.3)
        @occupying_job_finished.should == [ true ]
      end
    end

    class InputMapper
      include Enumerable

      def initialize(*values)
        @values = values
        @num_processed = 0
      end

      attr_reader :num_processed

      def each
        @values.each do |value|
          @num_processed += 1
          yield value
        end
      end
    end

    it ".map twice on the same parallel enumerable returns the correct results and re-processes the input", :focus do
      outputs_processed = 0
      input_mapper = InputMapper.new(1,2,3)
      enum = parallelizer.parallelize(input_mapper) do |x|
        outputs_processed += 1
        x
      end
      enum.map { |x| x }.should == [1,2,3]
      enum.map { |x| x }.should == [1,2,3]
      outputs_processed.should == 6
      input_mapper.num_processed.should == 6
    end

    it ".first and then .map on the same parallel enumerable returns the correct results and re-processes the input", :focus do
      outputs_processed = 0
      input_mapper = InputMapper.new(1,2,3)
      enum = parallelizer.parallelize(input_mapper) do |x|
        outputs_processed += 1
        x
      end
      enum.first.should == 1
      enum.map { |x| x }.should == [1,2,3]
      outputs_processed.should >= 4
      input_mapper.num_processed.should >= 4
    end

    it "two simultaneous enumerations throws an exception", :focus do
      enum = parallelizer.parallelize([1,2,3]) { |x| x }
      a = enum.enum_for(:each)
      a.next
      expect do
        b = enum.enum_for(:each)
        b.next
      end.to raise_error
    end
  end

  context "With a Parallelizer with 0 threads" do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(0)
    end

    context "And main_thread_processing on" do
      it "succeeds in running" do
        parallelizer.parallelize([0.5]) { |x| x*2 }.to_a.should == [1]
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
end
