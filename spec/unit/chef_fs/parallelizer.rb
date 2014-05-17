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
    parallelizer.stop
  end

  context 'With a Parallelizer with 5 threads' do
    let :parallelizer do
      Chef::ChefFS::Parallelizer.new(5)
    end

    def parallelize(inputs, options = {}, &block)
      parallelizer.parallelize(inputs, { :main_thread_processing => false }.merge(options), &block)
    end

    context "With :ordered => false (unordered output)" do
      it "An empty input produces an empty output" do
        parallelize([], :ordered => false) do
          sleep 10
        end.to_a == []
        elapsed_time.should < 1
      end

      it "10 sleep(0.5)s complete within 2 seconds" do
        parallelize(1.upto(10), :ordered => false) do |i|
          sleep 0.5
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 2
      end

      it "The output comes as soon as it is available" do
        enum = parallelize([0.5,0.3,0.1], :ordered => false) do |val|
          sleep val
          val
        end.enum_for(:each_with_index)
        enum.next.should == [ 0.1, 2 ]
        elapsed_time.should < 0.3
        enum.next.should == [ 0.3, 1 ]
        elapsed_time.should < 0.5
        enum.next.should == [ 0.5, 0 ]
        elapsed_time.should < 0.7
      end

      it "An exception in input is passed through but does NOT stop processing" do
        enum = parallelize(EnumerableWithException.new(0.5,0.3,0.1), :ordered => false) { |x| sleep(x); x }.enum_for(:each)
        enum.next.should == 0.1
        elapsed_time.should > 0.1
        enum.next.should == 0.3
        enum.next.should == 0.5
        expect { enum.next }.to raise_error 'hi'
        elapsed_time.should < 0.7
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
        elapsed_time.should > 0.19
        enum.next.should == 0.3
        expect { enum.next }.to raise_error
        elapsed_time.should < 0.5
        processed.should == 3
      end
    end

    context "With :ordered => true (ordered output)" do
      it "An empty input produces an empty output" do
        parallelize([]) do
          sleep 10
        end.to_a == []
        elapsed_time.should < 1
      end

      it "10 sleep(0.5)s complete within 2 seconds" do
        parallelize(1.upto(10)) do
          sleep 0.5
          'x'
        end.to_a.should == %w(x x x x x x x x x x)
        elapsed_time.should < 2
      end

      it "Output comes in the order of the input" do
        enum = parallelize([0.5,0.3,0.1]) do |val|
          sleep val
          val
        end.enum_for(:each_with_index)
        enum.next.should == [ 0.5, 0 ]
        enum.next.should == [ 0.3, 1 ]
        enum.next.should == [ 0.1, 2 ]
        elapsed_time.should < 0.7
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

      it "Exceptions in output are raised in the correct sequence but do NOT stop processing" do
        processed = 0
        enum = parallelize([0.2,0.1,'x',0.3]) do |x|
          sleep(x)
          processed += 1
          x
        end.enum_for(:each)
        enum.next.should == 0.2
        enum.next.should == 0.1
        expect { enum.next }.to raise_error
        elapsed_time.should > 0.25
        elapsed_time.should < 0.55
        processed.should == 3
      end
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
        @thread = Thread.new do
          parallelizer.parallelize([0], :main_thread_processing => false) { |x| started = true; sleep(0.3) }.wait
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
          x
        end.to_a.should == [ 1 ]
        elapsed_time.should > 0.3
      end
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
