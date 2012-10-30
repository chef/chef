#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

describe Chef::Resource::Env do

  before(:each) do
    @resource = Chef::Resource::Env.new("FOO")
  end

  it "should create a new Chef::Resource::Env" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Env)
  end

  it "should have a name" do
    @resource.name.should eql("FOO")
  end

  it "should have a default action of 'create'" do
    @resource.action.should eql(:create)
  end

  { :create => false, :delete => false, :modify => false, :flibber => true }.each do |action,bad_value|
    it "should #{bad_value ? 'not' : ''} accept #{action.to_s}" do
      if bad_value
        lambda { @resource.action action }.should raise_error(ArgumentError)
      else
        lambda { @resource.action action }.should_not raise_error(ArgumentError)
      end
    end
  end

  it "should use the object name as the key_name by default" do
    @resource.key_name.should eql("FOO")
  end

  it "should accept a string as the env value via 'value'" do
    lambda { @resource.value "bar" }.should_not raise_error(ArgumentError)
  end

  it "should not accept a Hash for the env value via 'to'" do
    lambda { @resource.value Hash.new }.should raise_error(ArgumentError)
  end

  it "should allow you to set an env value via 'to'" do
    @resource.value "bar"
    @resource.value.should eql("bar")
  end

  describe "when it has key name and value" do
    before do 
      @resource.key_name("charmander")
      @resource.value("level7")
      @resource.delim("hi")
    end

    it "describes its state" do
      state = @resource.state
      state[:value].should == "level7"
    end

    it "returns the key name as its identity" do
      @resource.identity.should == "charmander"
    end
  end

end
