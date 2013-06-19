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

require 'spec_helper'

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

  it "asserts that a value returns false from a predicate method" do
    lambda do
      @vo.validate({:not_blank => "should pass"},
                   {:not_blank => {:cannot_be => :nil, :cannot_be => :empty}})
    end.should_not raise_error
    lambda do
      @vo.validate({:not_blank => ""},
                   {:not_blank => {:cannot_be => :nil, :cannot_be => :empty}})
    end.should raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "should set and return a value, then return the same value" do
    value = "meow"
    @vo.set_or_return(:test, value, {}).object_id.should == value.object_id
    @vo.set_or_return(:test, nil, {}).object_id.should == value.object_id
  end

  it "should set and return a default value when the argument is nil, then return the same value" do
    value = "meow"
    @vo.set_or_return(:test, nil, { :default => value }).object_id.should == value.object_id
    @vo.set_or_return(:test, nil, {}).object_id.should == value.object_id
  end

  it "should raise an ArgumentError when argument is nil and required is true" do
    lambda {
      @vo.set_or_return(:test, nil, { :required => true })
    }.should raise_error(ArgumentError)
  end

  it "should not raise an error when argument is nil and required is false" do
    lambda {
      @vo.set_or_return(:test, nil, { :required => false })
    }.should_not raise_error(ArgumentError)
  end

  it "should set and return @name, then return @name for foo when argument is nil" do
    value = "meow"
    @vo.set_or_return(:name, value, { }).object_id.should == value.object_id
    @vo.set_or_return(:foo, nil, { :name_attribute => true }).object_id.should == value.object_id
  end

  it "should allow DelayedEvaluator instance to be set for value regardless of restriction" do
    value = Chef::DelayedEvaluator.new{ 'test' }
    @vo.set_or_return(:test, value, {:kind_of => Numeric})
  end

  it "should raise an error when delayed evaluated attribute is not valid" do
    value = Chef::DelayedEvaluator.new{ 'test' }
    @vo.set_or_return(:test, value, {:kind_of => Numeric})
    lambda do
      @vo.set_or_return(:test, nil, {:kind_of => Numeric})
    end.should raise_error(Chef::Exceptions::ValidationFailed)
  end

  it "should create DelayedEvaluator instance when #lazy is used" do
    @vo.set_or_return(:delayed, @vo.lazy{ 'test' }, {})
    @vo.instance_variable_get(:@delayed).should be_a(Chef::DelayedEvaluator)
  end

  it "should execute block on each call when DelayedEvaluator" do
    value = 'fubar'
    @vo.set_or_return(:test, @vo.lazy{ value }, {})
    @vo.set_or_return(:test, nil, {}).should == 'fubar'
    value = 'foobar'
    @vo.set_or_return(:test, nil, {}).should == 'foobar'
    value = 'fauxbar'
    @vo.set_or_return(:test, nil, {}).should == 'fauxbar'
  end

  it "should not evaluate non DelayedEvaluator instances" do
    value = lambda{ 'test' }
    @vo.set_or_return(:test, value, {})
    @vo.set_or_return(:test, nil, {}).object_id.should == value.object_id
    @vo.set_or_return(:test, nil, {}).should be_a(Proc)
  end
  
end
