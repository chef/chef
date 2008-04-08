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

describe Chef::Node do
  before(:each) do
    @node = Chef::Node.new()
  end
  
  it "should create a new Chef::Node" do
     @node.should be_a_kind_of(Chef::Node)
  end

  it "should allow you to set a name with name(something)" do
    lambda { @node.name("latte") }.should_not raise_error
  end
  
  it "should return the name with name()" do
    @node.name("latte")
    @node.name.should eql("latte")
  end
  
  it "should always have a string for name" do
    lambda { @node.name(Hash.new) }.should raise_error(ArgumentError)
  end
  
  it "should have attributes" do
    @node.attribute.should be_a_kind_of(Hash)
  end
  
  it "should allow attributes to be accessed by name or symbol directly on node[]" do
    @node.attribute["locust"] = "something"
    @node[:locust].should eql("something")
    @node["locust"].should eql("something")
  end
  
  it "should return nil if it cannot find an attribute with node[]" do
    @node["secret"].should eql(nil)
  end
  
  it "should allow you to query whether an attribute exists with attribute?" do
    @node.attribute["locust"] = "something"
    @node.attribute?("locust").should eql(true)
    @node.attribute?("no dice").should eql(false)
  end
  
  it "should have an array of recipes that should be applied" do
    @node.recipes.should be_a_kind_of(Array)
  end
  
  it "should allow you to query whether or not it has a recipe applied with recipe?" do
    @node.recipes << "sunrise"
    @node.recipe?("sunrise").should eql(true)
    @node.recipe?("not at home").should eql(false)
  end
  
  it "should allow you to set recipes with arguments" do
    @node.recipes "one", "two"
    @node.recipe?("one").should eql(true)
    @node.recipe?("two").should eql(true)
  end
  
  it "should allow you to set an attribute via method_missing" do
    @node.sunshine "is bright"
    @node.attribute[:sunshine].should eql("is bright")
  end
  
  it "should allow you get get an attribute via method_missing" do
    @node.sunshine "is bright"
    @node.sunshine.should eql("is bright")
  end
  
  it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
    lambda { @node.sunshine }.should raise_error(ArgumentError)
  end
  
  it "should load a node from a ruby file" do
    @node.from_file(File.join(File.dirname(__FILE__), "..", "data", "nodes", "test.rb"))
    @node.name.should eql("ops1prod")
    @node.sunshine.should eql("in")
    @node.something.should eql("else")
    @node.recipes.should eql(["operations-master", "operations-monitoring"])
  end
  
  it "should raise an exception if the file cannot be found or read" do
    lambda { @node.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
  end
  
  it "should allow you to iterate over attributes with each_attribute" do
    @node.sunshine "is bright"
    @node.canada "is a nice place"
    seen_attributes = Hash.new
    @node.each_attribute do |a,v|
      seen_attributes[a] = v
    end
    seen_attributes.should have_key(:sunshine)
    seen_attributes.should have_key(:canada)
    seen_attributes[:sunshine].should == "is bright"
    seen_attributes[:canada].should == "is a nice place"
  end

end