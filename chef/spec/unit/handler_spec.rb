#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'spec_helper'

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
      @all_resources = [Chef::Resource::Cat.new('lolz'), Chef::Resource::ZenMaster.new('tzu')]
      @all_resources.first.updated = true
      @run_context.resource_collection.all_resources.replace(@all_resources)
      @run_status.run_context = @run_context
      @start_time = Time.now
      @end_time = @start_time + 4.2
      Time.stub!(:now).and_return(@start_time, @end_time)
      @run_status.start_clock
      @run_status.stop_clock
    end

    it "has a shortcut for the exception" do
      @handler.exception.should == @exception
    end

    it "has a shortcut for the backtrace" do
      @handler.backtrace.should == @backtrace
    end

    it "has a shortcut for all resources" do
      @handler.all_resources.should == @all_resources
    end

    it "has a shortcut for just the updated resources" do
      @handler.updated_resources.should == [@all_resources.first]
    end

    it "has a shortcut for the start time" do
      @handler.start_time.should == @start_time
    end

    it "has a shortcut for the end time" do
      @handler.end_time.should == @end_time
    end

    it "has a shortcut for the elapsed time" do
      @handler.elapsed_time.should == 4.2
    end

    it "has a shortcut for the node" do
      @handler.node.should == @node
    end

    it "has a shortcut for the run context" do
      @handler.run_context.should == @run_context
    end

    it "has a shortcut for the success? and failed? predicates" do
      @handler.success?.should be_false # becuase there's an exception
      @handler.failed?.should be_true
    end

    it "has a shortcut to the hash representation of the run status" do
      @handler.data.should == @run_status.to_hash
    end
  end

  describe "when running the report" do
    it "does not fail if the report handler raises an exception" do
      $report_ran = false
      def @handler.report
        $report_ran = true
        raise Exception, "I died the deth"
      end
      lambda {@handler.run_report_safely(@run_status)}.should_not raise_error
      $report_ran.should be_true
    end
    it "does not fail if the report handler does not raise an exception" do
      $report_ran = false
      def @handler.report
        $report_ran = true
        puts "I'm AOK here."
      end
      lambda {@handler.run_report_safely(@run_status)}.should_not raise_error
      $report_ran.should be_true
    end
  end

  # Hmm, no tests for report handlers, looks like
  describe "when running a report handler" do
    before do
      @run_context = Chef::RunContext.new(@node, {}, @events)
      @all_resources = [Chef::Resource::Cat.new('foo'), Chef::Resource::ZenMaster.new('moo')]
      @all_resources.first.updated = true
      @run_context.resource_collection.all_resources.replace(@all_resources)
      @run_status.run_context = @run_context
      @start_time = Time.now
      @end_time = @start_time + 4.2
      Time.stub!(:now).and_return(@start_time, @end_time)
      @run_status.start_clock
      @run_status.stop_clock 
    end
    
    it "has a shortcut for all resources" do
      @handler.all_resources.should == @all_resources
    end

    it "has a shortcut for just the updated resources" do
      @handler.updated_resources.should == [@all_resources.first]
    end

    it "has a shortcut for the start time" do
      @handler.start_time.should == @start_time
    end

    it "has a shortcut for the end time" do
      @handler.end_time.should == @end_time
    end

    it "has a shortcut for the elapsed time" do
      @handler.elapsed_time.should == 4.2
    end

    it "has a shortcut for the node" do
      @handler.node.should == @node
    end

    it "has a shortcut for the run context" do
      @handler.run_context.should == @run_context
    end

    it "has a shortcut for the success? and failed? predicates" do
      @handler.success?.should be_true 
      @handler.failed?.should be_false
    end

    it "has a shortcut to the hash representation of the run status" do
      @handler.data.should == @run_status.to_hash
    end
  end

  # and this would test the start handler
  describe "when running a start handler" do
    before do
      @start_time = Time.now
      Time.stub!(:now).and_return(@start_time)
      @run_status.start_clock
    end

    it "should not have all resources" do
      @handler.all_resources.should be_false
    end

    it "should not have updated resources" do
      @handler.updated_resources.should be_false
    end

    it "has a shortcut for the start time" do
      @handler.start_time.should == @start_time
    end

    it "does not have a shortcut for the end time" do
      @handler.end_time.should be_false
    end

    it "does not have a shortcut for the elapsed time" do
      @handler.elapsed_time.should be_false
    end

    it "has a shortcut for the node" do
      @handler.node.should == @node
    end

    it "does not have a shortcut for the run context" do
      @handler.run_context.should be_false
    end

    it "has a shortcut for the success? and failed? predicates" do
      @handler.success?.should be_true # for some reason this is true
      @handler.failed?.should be_false
    end

    it "has a shortcut to the hash representation of the run status" do
      @handler.data.should == @run_status.to_hash
    end
  end

end
