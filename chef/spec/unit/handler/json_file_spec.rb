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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Handler::JsonFile do
  before(:each) do
    @handler = Chef::Handler::JsonFile.new
  end

  describe "initialize" do
    it "should return a Chef::Handler" do
      @handler.should be_a_kind_of(Chef::Handler)
    end

    it "should return a Chef::Handler::JsonFile" do
      @handler.should be_a_kind_of(Chef::Handler::JsonFile)
    end

    it "should let you set config options" do
      h = Chef::Handler::JsonFile.new(:the_sun => "will rise")
      h.config[:the_sun].should == "will rise"
    end
  end

  describe "report" do
    before(:each) do
      @node = Chef::Node.new
      @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new)
      @run_context = Chef::RunContext.new(@node, @cookbook_collection)
      @runner = Chef::Runner.new(@run_context)
      @start_time = Time.now
      @end_time = Time.now
      @elapsed_time = @end_time - @start_time
      @exception = Exception.new("Boy howdy!")
      @file_mock = mock(File, :null_object => true)
      File.stub!(:open).and_yield(@file_mock)
    end

    it "should build a report" do
      @handler.stub!(:build_report_data).and_return({ "partial" => "success" })
      @file_mock.should_receive(:puts).with("{\n  \"partial\": \"success\"\n}")
      report = @handler.report(@node, @runner, @start_time, @end_time, @elapsed_time, @exception)
    end

    it "should save the report to a file" do
      Time.stub!(:now).and_return(Time.at(0))
      File.should_receive(:open).with("/var/chef/reports/chef-run-report-19691231160000.json", "w").and_yield(@file_mock)
      report = @handler.report(@node, @runner, @start_time, @end_time, @elapsed_time, @exception)
    end
  end
end
