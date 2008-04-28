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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

class TinyClass
  include Chef::Mixin::ParamsValidate
  
  def music(is_good=true)
    is_good
  end
end

describe Chef::Mixin::ParamsValidate do
  before(:each) do
     @vo = TinyClass.new()
  end
  
  it "should allow a hash and a hash as arguments to validate" do
    lambda { @vo.validate({:one => "two"}, {}) }.should_not raise_error(ArgumentError)
  end
  
  it "should raise an argument error if validate is called incorrectly" do
    lambda { @vo.validate("one", "two") }.should raise_error(ArgumentError)
  end
  
  it "should require validation map keys to be symbols or strings" do
    lambda { @vo.validate({:one => "two"}, { :one => true }) }.should_not raise_error(ArgumentError)
    lambda { @vo.validate({:one => "two"}, { "one" => true }) }.should_not raise_error(ArgumentError)
    lambda { @vo.validate({:one => "two"}, { Hash.new => true }) }.should raise_error(ArgumentError)
  end
  
  it "should allow options to be required with true" do
    lambda { @vo.validate({:one => "two"}, { :one => true }) }.should_not raise_error(ArgumentError)
  end
  
  it "should allow options to be optional with false" do
    lambda { @vo.validate({}, {:one => false})}.should_not raise_error(ArgumentError)
  end    
  
  it "should allow you to check what kind_of? thing an argument is with kind_of" do
    lambda { 
      @vo.validate(
        {:one => "string"}, 
        {
          :one => {
            :kind_of => String
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        {:one => "string"}, 
        {
          :one => {
            :kind_of => Array
          }
        }
      ) 
    }.should raise_error(ArgumentError)
  end
  
  it "should allow you to specify an argument is required with required" do
    lambda { 
      @vo.validate(
        {:one => "string"}, 
        {
          :one => {
            :required => true
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        {:two => "string"}, 
        {
          :one => {
            :required => true
          }
        }
      ) 
    }.should raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        {:two => "string"}, 
        {
          :one => {
            :required => false
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
  end
  
  it "should allow you to specify whether an object has a method with respond_to" do
    lambda { 
      @vo.validate(
        {:one => @vo}, 
        {
          :one => {
            :respond_to => "validate"
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        {:one => @vo}, 
        {
          :one => {
            :respond_to => "monkey"
          }
        }
      ) 
    }.should raise_error(ArgumentError)
  end
  
  it "should allow you to specify whether an object has all the given methods with respond_to and an array" do
    lambda { 
      @vo.validate(
        {:one => @vo}, 
        {
          :one => {
            :respond_to => ["validate", "music"]
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        {:one => @vo}, 
        {
          :one => {
            :respond_to => ["monkey", "validate"]
          }
        }
      ) 
    }.should raise_error(ArgumentError)
  end
  
  it "should let you set a default value with default => value" do
    arguments = Hash.new
    @vo.validate(arguments, {
      :one => {
        :default => "is the loneliest number"
      }
    })
    arguments[:one].should == "is the loneliest number"
  end
  
  it "should let you check regular expressions" do
    lambda { 
      @vo.validate(
        { :one => "is good" },
        {
          :one => {
            :regex => /^is good$/
          }
        }
      )
    }.should_not raise_error(ArgumentError)
    
    lambda { 
      @vo.validate(
        { :one => "is good" },
        {
          :one => {
            :regex => /^is bad$/
          }
        }
      )
    }.should raise_error(ArgumentError)
  end
  
  it "should let you specify your own callbacks" do
    lambda { 
      @vo.validate(
        { :one => "is good" },
        {
          :one => {
            :callbacks => {
              "should be equal to is good" => lambda { |a|
                a == "is good"
              },
            }
          }
        }
      )
    }.should_not raise_error(ArgumentError) 
    
    lambda { 
      @vo.validate(
        { :one => "is bad" },
        {
          :one => {
            :callbacks => {
              "should be equal to 'is good'" => lambda { |a|
                a == "is good"
              },
            }
          }
        }
      )
    }.should raise_error(ArgumentError)   
  end
  
  it "should let you combine checks" do
    args = { :one => "is good", :two => "is bad" }
    lambda { 
      @vo.validate(
        args,
        {
          :one => {
            :kind_of => String,
            :respond_to => [ :to_s, :upcase ],
            :regex => /^is good/,
            :callbacks => {
              "should be your friend" => lambda { |a|
                a == "is good"
              }
            },
            :required => true
          },
          :two => {
            :kind_of => String,
            :required => false
          },
          :three => { :default => "neato mosquito" }
        }
      )
    }.should_not raise_error(ArgumentError)
    args[:three].should == "neato mosquito"
    lambda {
      @vo.validate(
        args,
        {
          :one => {
            :kind_of => String,
            :respond_to => [ :to_s, :upcase ],
            :regex => /^is good/,
            :callbacks => {
              "should be your friend" => lambda { |a|
                a == "is good"
              }
            },
            :required => true
          },
          :two => {
            :kind_of => Hash,
            :required => false
          },
          :three => { :default => "neato mosquito" }
        }
      )
    }.should raise_error(ArgumentError)
  end
  
  it "should raise an ArgumentError if the validation map has an unknown check" do
    lambda { @vo.validate(
        { :one => "two" },
        {
          :one => {
            :busted => "check"
          }
        }
      )
    }.should raise_error(ArgumentError)
  end
  
  it "should accept keys that are strings in the options" do
    lambda {
      @vo.validate({ "one" => "two" }, { :one => { :regex => /^two$/ }}) 
    }.should_not raise_error(ArgumentError)
  end
  
  it "should allow an array to kind_of" do
    lambda { 
      @vo.validate(
        {:one => "string"}, 
        {
          :one => {
            :kind_of => [ String, Array ]
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    lambda { 
      @vo.validate(
        {:one => ["string"]}, 
        {
          :one => {
            :kind_of => [ String, Array ]
          }
        }
      ) 
    }.should_not raise_error(ArgumentError)
    lambda { 
      @vo.validate(
        {:one => Hash.new}, 
        {
          :one => {
            :kind_of => [ String, Array ]
          }
        }
      ) 
    }.should raise_error(ArgumentError)
  end
  
end