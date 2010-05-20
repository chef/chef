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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Handler do
  before(:each) do
    @handler = Chef::Handler.new
  end

  describe "initialize" do
    it "should return a Chef::Handler" do
      @handler.should be_a_kind_of(Chef::Handler)
    end

    it "should set the :path config option" do
      @handler.config[:path].should == "/var/chef/reports"
    end
  end

  describe "build_report_data" do
    before(:each) do
      @node = Chef::Node.new
      @run_context = Chef::RunContext.new(@node, Chef::CookbookCollection.new(Chef::CookbookLoader.new))
      @runner = Chef::Runner.new(@run_context)
      @start_time = Time.now
      @end_time = Time.now
      @elapsed_time = @end_time - @start_time
      @exception = Exception.new("Boy howdy!")
      @data = @handler.build_report_data(@node, @runner, @start_time, @end_time, @elapsed_time, @exception)
    end

    describe "node data" do
      it "should be present if passed" do
        @data[:node].should be(@node)
      end

      it "should be absent if not passed" do
        @data = @handler.build_report_data(nil, @runner, @start_time, @end_time, @elapsed_time, @exception)
        @data.has_key?(:node).should be(false)
      end
    end

    describe "resources" do
      describe "runner was passed" do
        before(:each) do
          @elvis = Chef::Resource::File.new("elvis", @run_context)
          @runner.run_context.resource_collection << @elvis 
          @metallica = Chef::Resource::File.new("metallica", @run_context)
          @metallica.updated = true
          @runner.run_context.resource_collection << @metallica 
          @data = @handler.build_report_data(@node, @runner, @start_time, @end_time, @elapsed_time, @exception)
        end

        it "resources=>all should contain the entire resource collection" do
          @data[:resources][:all].should == [ @elvis, @metallica ] 
        end
        it "resources=>updated should contain the updated resources" do
          @data[:resources][:updated].should == [ @metallica ] 
        end
      end
      
      it "resources data should not be included if runner was not passed" do
          @data = @handler.build_report_data(@node, nil, @start_time, @end_time, @elapsed_time, @exception)
        @data.has_key?(:resources).should == false
      end
    end

    describe "exceptions" do
      describe "was passed" do
        it "should set success to false" do
          @data[:success].should be(false)
        end

        it "should set the exception message" do
          @data[:exception][:message].should == @exception.message 
        end

        it "should set the exception backtrace" do
          @data[:exception][:backtrace].should == @exception.backtrace
        end
      end
    end

    it "should set sucess to true if an exception was not passed" do
      @data = @handler.build_report_data(@node, @runner, @start_time, @end_time, @elapsed_time, nil)
      @data[:success].should == true
    end

    describe "timing data" do
      it "should set the elapsed time" do
        @data[:elapsed_time].should == @elapsed_time
      end

      it "should set the start time" do
        @data[:start_time].should == @start_time
      end

      it "should set the end time" do
        @data[:end_time].should == @end_time
      end
    end

  end

end
