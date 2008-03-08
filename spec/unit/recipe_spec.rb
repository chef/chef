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

describe Marionette::Recipe do
  before(:each) do
    @recipe = Marionette::Recipe.new("hjk", "test", "node")
  end
 
  it "should load our zen_master resource" do
    lambda do
      @recipe.zen_master "monkey" do
        peace = true
      end
    end.should_not raise_error(ArgumentError)
  end
  
  it "should add our zen_master as a vertex" do
    @recipe.zen_master "monkey" do
      peace = true
    end
    @recipe.dg.each_vertex do |v|
      next if v == :top
      v.should be_kind_of(Marionette::Resource::ZenMaster)
    end
  end
  
  it "should graph our zen masters in the order they appear" do
    %w{monkey dog cat}.each do |name|
      @recipe.zen_master name do
        peace = true
      end
    end
    index = 0
    @recipe.dg.topsort_iterator do |v|
      case v
      when :top
        index.should eql(0)
      when v.name == "monkey"
        index.should eql(1)
      when v.name == "dog"
        index.should eql(2)
      when v.name == "cat"
        index.should eql(3)
      end
      index += 1
    end
  end
    
  it "should handle an instance_eval properly" do
    code = <<-CODE
zen_master "gnome" do
  peace = true
end
CODE
    lambda { @recipe.instance_eval(code) }.should_not raise_error
    @recipe.resources(:zen_master => "gnome").name.should eql("gnome")
  end

end