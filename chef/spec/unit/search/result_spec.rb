#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
require 'chef/search/result'

describe Chef::Search::Result do 
  before(:each) do
    @sr = Chef::Search::Result.new
  end

  describe "initialize" do
    it "should return a Chef::Search::Result" do
      @sr.should be_a_kind_of(Chef::Search::Result)
    end
  end

  describe "hash like behavior" do
    it "should let you set and retrieve data" do
      @sr[:one] = "two"
      @sr[:one].should == "two"
    end

    it "should let you enumerate with each" do
      @sr[:one] = "two"
      @sr[:three] = "four"
      seen = Hash.new
      @sr.each do |k,v|
        seen[k] = v
      end
      seen["one"].should == "two"
      seen["three"].should == "four"
    end
  end

  describe "auto-inflate to a nested hash" do
    it "should allow for _ seperated keys to be auto-inflated to nested hashes" do
      @sr["one_two_three"] = "four"
      @sr["one"]["two"]["three"].should == "four"
    end
  end

  describe "to_json" do
    it "should serialize to json" do
      @sr[:one] = "two"
      @sr[:three] = "four"
      @sr.to_json.should =~ /"one":"two"/
      @sr.to_json.should =~ /"three":"four"/
      @sr.to_json.should =~ /"json_class":"Chef::Search::Result"/
    end
  end

  describe "json_create" do
    before(:each) do
      @sr[:one] = "two"
      @sr[:three] = "four"
      @new_sr = JSON.parse(@sr.to_json) 
    end
  
    it "should create a new Chef::Search::Result" do
      @new_sr.should be_a_kind_of(Chef::Search::Result)
    end

    it "have all the keys of the original Chef::Search::Result" do
      @new_sr["one"].should == "two"
      @new_sr["three"].should == "four"
    end
  end
end
