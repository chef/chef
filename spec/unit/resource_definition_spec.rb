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

describe Chef::ResourceDefinition do
  before(:each) do
    @def = Chef::ResourceDefinition.new()
  end
  
  it "should accept a new definition with a symbol for a name" do
    lambda { 
      @def.define :smoke do 
      end
    }.should_not raise_error(ArgumentError)
    lambda { 
      @def.define "george washington" do
      end 
    }.should raise_error(ArgumentError)
    @def.name.should eql(:smoke)
  end
  
  it "should accept a new definition with a hash" do
    lambda { 
      @def.define :smoke, :cigar => "cuban", :cigarette => "marlboro" do
      end
    }.should_not raise_error(ArgumentError)
  end
  
  it "should expose the prototype hash params in the params hash" do
    @def.define :smoke, :cigar => "cuban", :cigarette => "marlboro" do
    end
    @def.params[:cigar].should eql("cuban")
    @def.params[:cigarette].should eql("marlboro")
  end

  it "should store the block passed to define as a proc under recipe" do
    @def.define :smoke do
      "I am what I am"
    end
    @def.recipe.should be_a_kind_of(Proc)
    @def.recipe.call.should eql("I am what I am")
  end
  
  it "should set paramaters based on method_missing" do
    @def.mind "to fly"
    @def.params[:mind].should eql("to fly")
  end
  
  it "should raise an exception if prototype_params is not a hash" do
    lambda {
      @def.define :monkey, Array.new do
      end
    }.should raise_error(ArgumentError)
  end
  
  it "should raise an exception if define is called without a block" do
    lambda { 
      @def.define :monkey
    }.should raise_error(ArgumentError)
  end
  
  it "should load a description from a file" do
    @def.from_file(File.join(File.dirname(__FILE__), "..", "data", "definitions", "test.rb"))
    @def.name.should eql(:rico_suave)
    @def.params[:rich].should eql("smooth")
  end  
end