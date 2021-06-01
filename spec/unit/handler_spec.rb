#
# Author:: Adam Jacob (<adam@chef.io>)
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

require "spec_helper"

describe Chef::Handler do
  before(:each) do
    @handler = Chef::Handler.new

    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_status = Chef::RunStatus.new(@node, @events)

    @handler.instance_variable_set(:@run_status, @run_status)
  end

  describe "when accessing the run status" do
    before do
      @backtrace = caller
      @exception = Exception.new("epic_fail")
      @exception.set_backtrace(@backtrace)
      @run_status.exception = @exception
      @run_context = Chef::RunContext.new(@node, {}, @events)
      @all_resources = [Chef::Resource::Cat.new("lolz"), Chef::Resource::ZenMaster.new("tzu")]
      @all_resources.first.updated_by_last_action true
      @handler.instance_variable_set(:@all_resources, @all_resources)
      @handler.instance_variable_set(:@updated_resources, [@all_resources.first])
      @run_context.resource_collection.all_resources.replace(@all_resources)
      @run_status.run_context = @run_context
      @start_time = Time.now
      @end_time = @start_time + 4.2
      allow(Time).to receive(:now).and_return(@start_time, @end_time)
      @run_status.start_clock
      @run_status.stop_clock
    end

    it "has a shortcut for the exception" do
      expect(@handler.exception).to eq(@exception)
    end

    it "has a shortcut for the backtrace" do
      expect(@handler.backtrace).to eq(@backtrace)
    end

    it "has a shortcut for all resources" do
      expect(@handler.all_resources).to eq(@all_resources)
    end

    it "has a shortcut for just the updated resources" do
      expect(@handler.updated_resources).to eq([@all_resources.first])
    end

    it "has a shortcut for the start time" do
      expect(@handler.start_time).to eq(@start_time)
    end

    it "has a shortcut for the end time" do
      expect(@handler.end_time).to eq(@end_time)
    end

    it "has a shortcut for the elapsed time" do
      expect(@handler.elapsed_time).to eq(4.2)
    end

    it "has a shortcut for the node" do
      expect(@handler.node).to eq(@node)
    end

    it "has a shortcut for the run context" do
      expect(@handler.run_context).to eq(@run_context)
    end

    it "has a shortcut for the success? and failed? predicates" do
      expect(@handler.success?).to be_falsey # because there's an exception
      expect(@handler.failed?).to be_truthy
    end

    it "has a shortcut to the hash representation of the run status" do
      expect(@handler.data).to eq(@run_status.to_hash)
    end
  end

  describe "when running the report" do
    it "does not fail if the report handler raises an exception" do
      $report_ran = false
      def @handler.report
        $report_ran = true
        raise Exception, "I died the deth"
      end
      expect { @handler.run_report_safely(@run_status) }.not_to raise_error
      expect($report_ran).to be_truthy
    end
    it "does not fail if the report handler does not raise an exception" do
      $report_ran = false
      def @handler.report
        $report_ran = true
      end
      expect { @handler.run_report_safely(@run_status) }.not_to raise_error
      expect($report_ran).to be_truthy
    end
  end

  # Hmm, no tests for report handlers, looks like
  describe "when running a report handler" do
    before do
      @run_context = Chef::RunContext.new(@node, {}, @events)
      @all_resources = [Chef::Resource::Cat.new("foo"), Chef::Resource::ZenMaster.new("moo")]
      @all_resources.first.updated_by_last_action true
      @handler.instance_variable_set(:@all_resources, @all_resources)
      @handler.instance_variable_set(:@updated_resources, [@all_resources.first])
      @run_context.resource_collection.all_resources.replace(@all_resources)
      @run_status.run_context = @run_context
      @start_time = Time.now
      @end_time = @start_time + 4.2
      allow(Time).to receive(:now).and_return(@start_time, @end_time)
      @run_status.start_clock
      @run_status.stop_clock
    end

    it "has a shortcut for all resources" do
      expect(@handler.all_resources).to eq(@all_resources)
    end

    it "has a shortcut for just the updated resources" do
      expect(@handler.updated_resources).to eq([@all_resources.first])
    end

    it "has a shortcut for the start time" do
      expect(@handler.start_time).to eq(@start_time)
    end

    it "has a shortcut for the end time" do
      expect(@handler.end_time).to eq(@end_time)
    end

    it "has a shortcut for the elapsed time" do
      expect(@handler.elapsed_time).to eq(4.2)
    end

    it "has a shortcut for the node" do
      expect(@handler.node).to eq(@node)
    end

    it "has a shortcut for the run context" do
      expect(@handler.run_context).to eq(@run_context)
    end

    it "has a shortcut for the success? and failed? predicates" do
      expect(@handler.success?).to be_truthy
      expect(@handler.failed?).to be_falsey
    end

    it "has a shortcut to the hash representation of the run status" do
      expect(@handler.data).to eq(@run_status.to_hash)
    end
  end

  # and this would test the start handler
  describe "when running a start handler" do
    before do
      @handler.instance_variable_set(:@all_resources, [])
      @handler.instance_variable_set(:@updated_resources, [])
      @start_time = Time.now
      allow(Time).to receive(:now).and_return(@start_time)
      @run_status.start_clock
    end

    it "should not have all resources" do
      expect(@handler.all_resources).to be_empty
    end

    it "should not have updated resources" do
      expect(@handler.updated_resources).to be_empty
    end

    it "has a shortcut for the start time" do
      expect(@handler.start_time).to eq(@start_time)
    end

    it "does not have a shortcut for the end time" do
      expect(@handler.end_time).to be_falsey
    end

    it "does not have a shortcut for the elapsed time" do
      expect(@handler.elapsed_time).to be_falsey
    end

    it "has a shortcut for the node" do
      expect(@handler.node).to eq(@node)
    end

    it "does not have a shortcut for the run context" do
      expect(@handler.run_context).to be_falsey
    end

    it "has a shortcut for the success? and failed? predicates" do
      expect(@handler.success?).to be_truthy # for some reason this is true
      expect(@handler.failed?).to be_falsey
    end

    it "has a shortcut to the hash representation of the run status" do
      expect(@handler.data).to eq(@run_status.to_hash)
    end
  end

  describe "library report handler" do
    before do
      # we need to lazily declare this after we have reset Chef::Config in the default rspec before handler
      class MyTestHandler < Chef::Handler
        handler_for :report, :exception, :start

        class << self
          attr_accessor :ran_report
        end

        def report
          self.class.ran_report = true
        end
      end
    end

    it "gets added to Chef::Config[:report_handlers]" do
      expect(Chef::Config[:report_handlers].include?(MyTestHandler)).to be true
    end

    it "gets added to Chef::Config[:exception_handlers]" do
      expect(Chef::Config[:exception_handlers].include?(MyTestHandler)).to be true
    end

    it "gets added to Chef::Config[:start_handlers]" do
      expect(Chef::Config[:start_handlers].include?(MyTestHandler)).to be true
    end

    it "runs the report handler" do
      Chef::Handler.run_report_handlers(@run_status)
      expect(MyTestHandler.ran_report).to be true
    end

    it "runs the exception handler" do
      Chef::Handler.run_exception_handlers(@run_status)
      expect(MyTestHandler.ran_report).to be true
    end

    it "runs the start handler" do
      Chef::Handler.run_start_handlers(@run_status)
      expect(MyTestHandler.ran_report).to be true
    end
  end

  describe "library singleton report handler" do
    before do
      # we need to lazily declare this after we have reset Chef::Config in the default rspec before handler
      class MyTestHandler < Chef::Handler
        handler_for :report, :exception, :start

        include Singleton

        attr_accessor :ran_report

        def report
          self.ran_report = true
        end
      end
    end

    it "gets added to Chef::Config[:report_handlers]" do
      expect(Chef::Config[:report_handlers].include?(MyTestHandler)).to be true
    end

    it "gets added to Chef::Config[:exception_handlers]" do
      expect(Chef::Config[:exception_handlers].include?(MyTestHandler)).to be true
    end

    it "gets added to Chef::Config[:start_handlers]" do
      expect(Chef::Config[:start_handlers].include?(MyTestHandler)).to be true
    end

    it "runs the report handler" do
      Chef::Handler.run_report_handlers(@run_status)
      expect(MyTestHandler.instance.ran_report).to be true
    end

    it "runs the exception handler" do
      Chef::Handler.run_exception_handlers(@run_status)
      expect(MyTestHandler.instance.ran_report).to be true
    end

    it "runs the start handler" do
      Chef::Handler.run_start_handlers(@run_status)
      expect(MyTestHandler.instance.ran_report).to be true
    end
  end
end
