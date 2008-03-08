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

require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Marionette::Resource do
  before(:each) do
    @resource = Marionette::Resource.new("funk")
  end
  
  it "should have a name" do
    @resource.name.should eql("funk")
  end
  
  it "should create a new Marionette::Resource" do
    @resource.should be_a_kind_of(Marionette::Resource)
  end
  
  it "should not be valid without a name" do
    lambda { @resource.name false }.should raise_error(ArgumentError)
  end
  
  it "should always have a string for name" do
    lambda { @resource.name Hash.new }.should raise_error(ArgumentError)
  end
  
  it "should accept true or false for noop" do
    lambda { @resource.noop true }.should_not raise_error(ArgumentError)
    lambda { @resource.noop false }.should_not raise_error(ArgumentError)
    lambda { @resource.noop "eat it" }.should raise_error(ArgumentError)
  end
  
  it "should make itself dependent on required resources" do
    lambda { 
      @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee")) 
    }.should_not raise_error
    lambda { 
      @resource.requires @resource.resources(:zen_master => "coffee")
    }.should_not raise_error
    
    @resource.deps.topsort_iterator.to_a[0].name.should eql("coffee")
    @resource.deps.topsort_iterator.to_a[1].name.should eql("funk")
  end
  
  it "should make before resources appear later in the graph" do
    lambda { 
      @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee")) 
    }.should_not raise_error
    lambda { 
      @resource.before @resource.resources(:zen_master => "coffee")
    }.should_not raise_error
    
    @resource.deps.topsort_iterator.to_a[0].name.should eql("funk")
    @resource.deps.topsort_iterator.to_a[1].name.should eql("coffee")    
  end
  
  it "should make notified resources appear in the actions hash" do
    @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee"))
    @resource.notifies :reload, @resource.resources(:zen_master => "coffee")
    @resource.actions[:reload][0].name.should eql("coffee")
  end
  
  it "should make notified resources happen later in the graph" do
    @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee"))
    @resource.notifies :reload, @resource.resources(:zen_master => "coffee")
    @resource.deps.topsort_iterator.to_a[0].name.should eql("funk")
    @resource.deps.topsort_iterator.to_a[1].name.should eql("coffee")
  end
  
  it "should make subscribed resources appear in the actions hash" do
    @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee"))
    zr = @resource.resources(:zen_master => "coffee")
    @resource.subscribes :reload, zr
    zr.actions[:reload][0].name.should eql("funk")
  end

  it "should make subscribed resources happen earlier in the graph" do
    @resource.dg.add_vertex(Marionette::Resource::ZenMaster.new("coffee"))
    zr = @resource.resources(:zen_master => "coffee")
    @resource.subscribes :reload, zr
    @resource.deps.topsort_iterator.to_a[1].name.should eql("funk")
    @resource.deps.topsort_iterator.to_a[0].name.should eql("coffee")
  end
  
  it "should return a value if not defined" do
    zm = Marionette::Resource::ZenMaster.new("coffee")
    zm.something(true).should eql(true)
    zm.something.should eql(true)
    zm.something(false).should eql(false)
    zm.something.should eql(false)
  end
  
#  it "should serialize to yaml" do
#    yaml_output = <<-DESC
#--- !ruby/object:Marionette::Resource 
#alias: 
#before: 
#name: funk
#noop: 
#notify: 
#require: 
#subscribe: 
#tag: 
#DESC
#    @resource.to_yaml.should eql(yaml_output)
#  end  
  

end