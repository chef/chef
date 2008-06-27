#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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
  
  it "should call search_each if a block is given" do
    cp = lambda { |n| "noting to do here" }
    @mf.should_receive(:search_each).with("type:node AND (tag:monkey)", &cp)
    do_search(:node, "tag:monkey", &cp)
  end
  
  it "should call search if a block is not given" do
    @mf.should_receive(:search).with("type:node AND (tag:monkey)")
    do_search(:node, "tag:monkey")
  end
  
  it "should return the search results" do
    @mf.should_receive(:search).with("type:node AND (tag:monkey)").and_return(true)
    do_search(:node, "tag:monkey").should eql(true)
  end
end