#
# Author:: AJ Christensen (<aj@opscode.com>)
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "spec_helper"))
require 'chef/cookbook/metadata/version'

describe Chef::Cookbook::Metadata::Version do
  before do
    @ccmv = Chef::Cookbook::Metadata::Version
    @v = @ccmv.new "0.0.0"
  end

  describe "initialize" do
  
    it "should create a new version object" do
      @ccmv.new("0.0.0").should be_a(@ccmv)
    end

    describe "with a string" do

      it "should raise an error with an invalid string" do
        lambda { @ccmv.new("poos") }.should(
          raise_error("Metadata version 'poos' does not match 'x.y.z' or 'x.y'")
        )
      end

      it "should accept a 3 digit, two-decimal version string" do
        lambda { @ccmv.new("1.2.3") }.should_not raise_error
      end

      it "should accept a 2 digit, one-decimal version string" do
        lambda { @ccmv.new("1.2") }.should_not raise_error
      end
    end
  
  end

  describe "inspect" do
    it "should turn itself into a string" do
      @v.inspect.should == "0.0.0"
    end
  end

  describe "_parse" do

    it "should raise an error when called with no arg" do
      lambda { @v._parse }.should raise_error("Metadata version '' does not match 'x.y.z' or 'x.y'")
    end

    it "should raise an error when called with a non matching string" do
      lambda { @v._parse("poopypants") }.should raise_error("Metadata version 'poopypants' does not match 'x.y.z' or 'x.y'")
    end

    it "should parse '1.2' into [1, 2, 0]" do
      @v._parse("1.2").should == [1, 2, 0]
    end

    it "should parse '5.6.7' into [5, 6, 7]" do
      @v._parse("5.6.7").should == [5, 6, 7]
    end

  end

  describe "<=> (compare)" do
    it "should respond to <=>" do
      @v.should respond_to(:<=>)
    end

    it "should correctly sort a full array of versions" do
      %w{0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 1.1.0 1.1.1}.collect { |s|
        @ccmv.new(s)
      }.sort.should == (
        %w{0.0.0 0.0.1 0.1.0 0.1.1 1.0.0 1.1.0 1.1.1}.collect { |s| @ccmv.new(s) }
      )
    end

    it "should correctly sort an EVEN crazier array of versions" do
      %w{9.8.7 1.0.0 1.2.3 4.4.6 4.5.6 0.8.6 4.5.5 5.9.8 3.5.7}.collect { |s|
        @ccmv.new(s)
      }.sort.should == (
        %w{0.8.6 1.0.0 1.2.3 3.5.7 4.4.6 4.5.5 4.5.6 5.9.8 9.8.7}.collect { |s| @ccmv.new(s) }
      )
    end

    describe "a few truths" do
      # Is this DRY, or nasty?
      [ 
        [ "0.0.0", :>, "0.0.0", false ],
        [ "0.0.0", :>=, "0.0.0", true ],
        [ "0.0.0", :==, "0.0.0", true ],
        [ "0.0.0", :<=, "0.0.0", true ],
        [ "0.0.0", :<, "0.0.0", false ],
        [ "0.0.0", :>, "0.0.1", false ],
        [ "0.0.0", :>=, "0.0.1", false ],
        [ "0.0.0", :==, "0.0.1", false ],
        [ "0.0.0", :<=, "0.0.1", true ],
        [ "0.0.0", :<, "0.0.1", true ],
        [ "0.0.1", :>, "0.0.1", false ],
        [ "0.0.1", :>=, "0.0.1", true ],
        [ "0.0.1", :==, "0.0.1", true ],
        [ "0.0.1", :<=, "0.0.1", true ],
        [ "0.0.1", :<, "0.0.1", false ],
        [ "0.1.0", :>, "0.1.0", false ],
        [ "0.1.0", :>=, "0.1.0", true ],
        [ "0.1.0", :==, "0.1.0", true ],
        [ "0.1.0", :<=, "0.1.0", true ],
        [ "0.1.0", :<, "0.1.0", false ],
        [ "0.1.1", :>, "0.1.1", false ],
        [ "0.1.1", :>=, "0.1.1", true ],
        [ "0.1.1", :==, "0.1.1", true ],
        [ "0.1.1", :<=, "0.1.1", true ],
        [ "0.1.1", :<, "0.1.1", false ],
        [ "1.0.0", :>, "1.0.0", false ],
        [ "1.0.0", :>=, "1.0.0", true ],
        [ "1.0.0", :==, "1.0.0", true ],
        [ "1.0.0", :<=, "1.0.0", true ],
        [ "1.0.0", :<, "1.0.0", false ],
        [ "1.0.0", :>, "0.0.1", true ],
        [ "1.0.0", :>=, "1.9.2", false ],
        [ "1.0.0", :==, "9.7.2", false ],
        [ "1.0.0", :<=, "1.9.1", true ],
        [ "1.0.0", :<, "1.9.0", true ],
        [ "1.2.2", :>, "1.2.1", true ],
        [ "1.2.2", :>=, "1.2.1", true ],
        [ "1.2.2", :==, "1.2.1", false ],
        [ "1.2.2", :<=, "1.2.1", false ],
        [ "1.2.2", :<, "1.2.1", false ]
      ].each do |spec|
        it "(#{spec.first(3).join(' ')}) should be #{spec[3]}" do
          @ccmv.new(spec[0]).send(spec[1], @ccmv.new(spec[2])).should == spec[3]
        end
      end

    end
  end

  describe "to_s" do
    it "should turn itself into a string" do
      @v.to_s.should == "0.0.0"
    end
  end
end
