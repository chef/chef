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
    lambda { @resource.name = nil }.should raise_error(ArgumentError)
  end
  
  it "should always have a string for name" do
    lambda { @resource.name = Hash.new }.should raise_error(ArgumentError)
  end
  
  it "should have a string for alias" do
    lambda { @resource.alias = nil }.should raise_error(ArgumentError)
    lambda { @resource.alias = 'foo' }.should_not raise_error(ArgumentError)
    @resource.alias.should eql("foo")
  end
  
  it "should accept true or false for noop" do
    lambda { @resource.noop = true }.should_not raise_error(ArgumentError)
    lambda { @resource.noop = false }.should_not raise_error(ArgumentError)
    lambda { @resource.noop = "eat it" }.should raise_error(ArgumentError)
  end
  
  it "should serialize to yaml" do
    yaml_output = <<-DESC
--- !ruby/object:Marionette::Resource 
alias: 
before: 
name: funk
noop: 
notify: 
require: 
subscribe: 
tag: 
DESC
    @resource.to_yaml.should eql(yaml_output)
  end  
  
  it "should find a resource by symbol and name, or array of names" do
  #  %w{monkey dog cat}.each do |name|
  #    @recipe.zen_master name do
  #      peace = true
  #    end
  #  end
  #  doggie = @recipe.resource(:zen_master => "dog")
  #  doggie.name.should eql("dog") # clever, I know
  #  multi_zen = [ "dog", "monkey" ]
  #  zen_array = @recipe.resource(:zen_master => multi_zen)
  #  zen_array.length.should eql(2)
  #  zen_array.each_index do |i|
  #    zen_array[i].name.should eql(multi_zen[i])
  #    zen_array[i].resource_name.should eql(:zen_master)
  #  end
  end
end