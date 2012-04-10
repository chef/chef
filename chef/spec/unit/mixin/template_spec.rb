#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

class TinyTemplateClass; include Chef::Mixin::Template; end
require 'cgi'
describe Chef::Mixin::Template, "render_template" do

  before :each do
    @template = TinyTemplateClass.new
  end

  it "should render the template evaluated in the given context" do
    @template.render_template("<%= @foo %>", { :foo => "bar" }) do |tmp|
      tmp.open.read.should == "bar"
    end
  end

  it "should provide a node method to access @node" do
    @template.render_template("<%= node %>",{:node => "tehShizzle"}) do |tmp|
      tmp.open.read.should == "tehShizzle"
    end
  end

  it "should yield the tempfile it renders the template to" do
    @template.render_template("abcdef", {}) do |tempfile|
      tempfile.should be_kind_of(Tempfile)
    end
  end

  describe "when an exception is raised in the template" do
    def do_raise
      @context = {:chef => "cool"}
      @template.render_template("foo\nbar\nbaz\n<%= this_is_not_defined %>\nquin\nqunx\ndunno", @context) {|r| r}
    end

    it "should catch and re-raise the exception as a TemplateError" do
      lambda { do_raise }.should raise_error(Chef::Mixin::Template::TemplateError)
    end

    it "should raise an error if an attempt is made to access node but it is nil" do
      lambda {@template.render_template("<%= node %>",{}) {|r| r}}.should raise_error(Chef::Mixin::Template::TemplateError)
    end

    describe "the raised TemplateError" do
      before :each do
        begin
          do_raise
        rescue Chef::Mixin::Template::TemplateError => e
          @exception = e
        end
      end

      it "should have the original exception" do
        @exception.original_exception.should be
        @exception.original_exception.message.should =~ /undefined local variable or method `this_is_not_defined'/
      end

      it "should determine the line number of the exception" do
        @exception.line_number.should == 4
      end

      it "should provide a source listing of the template around the exception" do
        @exception.source_listing.should == "  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx"
      end

      it "should provide the evaluation context of the template" do
        @exception.context.should == @context
      end

      it "should defer the message to the original exception" do
        @exception.message.should =~ /undefined local variable or method `this_is_not_defined'/
      end

      it "should provide a nice source location" do
        @exception.source_location.should == "on line #4"
      end

      it "should create a pretty output for the terminal" do
        @exception.to_s.should =~ /Chef::Mixin::Template::TemplateError/
        @exception.to_s.should =~ /undefined local variable or method `this_is_not_defined'/
        @exception.to_s.should include("  2: bar\n  3: baz\n  4: <%= this_is_not_defined %>\n  5: quin\n  6: qunx")
        @exception.to_s.should include(@exception.original_exception.backtrace.first)
      end
    end
  end
end

