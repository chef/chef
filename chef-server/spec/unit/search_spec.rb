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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Search, "initialize method" do
  before(:each) do
    @mf = mock("Ferret::Index::Index", :null_object => true)
    Ferret::Index::Index.stub!(:new).and_return(@mf)
  end
  
  it "should build a Chef::Search object" do
    Chef::Search.new.should be_a_kind_of(Chef::Search)
  end

  it "should build a Ferret search backend" do
    Ferret::Index::Index.should_receive(:new).and_return(@mf)
    Chef::Search.new
  end
end

describe Chef::Search, "search method" do
  before(:each) do
    @mf = mock("Ferret::Index::Index", :null_object => true)
  end
  
  def do_search(type, query, &block)
    Ferret::Index::Index.stub!(:new).and_return(@mf)
    cs = Chef::Search.new
    if Kernel.block_given?
      cs.search(type, query, &block)
    else
      cs.search(type, query)
    end
  end
  
  it "should build the search query from the type and query provided" do
    Ferret::Index::Index.stub!(:new).and_return(@mf)
    cs = Chef::Search.new
    cs.should_receive(:build_search_query).with(:node, "tag:monkey")
    cs.search(:node, "tag:monkey")
  end
  
  it "should call search_each with the custom block if a block is given" do
    cp = lambda { |n,u| "noting to do here" }
    @mf.should_receive(:search_each).with("index_name:node AND (tag:monkey)", { :limit => :all }, &cp)
    do_search(:node, "tag:monkey", &cp)
  end
  
  it "should call search_each if a block is not given" do
    @mf.should_receive(:search_each).with("index_name:node AND (tag:monkey)", {:limit => :all})
    do_search(:node, "tag:monkey")
  end
  
  it "should return the search results" do
    @mf.should_receive(:search_each).with("index_name:node AND (tag:monkey)", :limit => :all).and_return(true)
    do_search(:node, "tag:monkey").should eql([])
  end
end