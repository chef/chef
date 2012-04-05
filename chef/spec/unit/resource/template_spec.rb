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

describe Chef::Resource::Template do

  before(:each) do
    @resource = Chef::Resource::Template.new("fakey_fakerton")
  end  

  describe "initialize" do
    it "should create a new Chef::Resource::Template" do
      @resource.should be_a_kind_of(Chef::Resource)
      @resource.should be_a_kind_of(Chef::Resource::File)
      @resource.should be_a_kind_of(Chef::Resource::Template)
    end
  end

  describe "source" do
    it "should accept a string for the template source" do
      @resource.source "something"
      @resource.source.should eql("something")
    end

    it "should have a default based on the param name with .erb appended" do
      @resource.source.should eql("fakey_fakerton.erb")
    end

    it "should use only the basename of the file as the default" do
      r = Chef::Resource::Template.new("/tmp/obit/fakey_fakerton")
      r.source.should eql("fakey_fakerton.erb")
    end
  end
  
  describe "variables" do
    it "should accept a hash for the variable list" do
      @resource.variables({ :reluctance => :awkward })
      @resource.variables.should == { :reluctance => :awkward }
    end
  end
  
  describe "cookbook" do
    it "should accept a string for the cookbook name" do
      @resource.cookbook("foo")
      @resource.cookbook.should == "foo"
    end
    
    it "should default to nil" do
      @resource.cookbook.should == nil
    end
  end

  describe "local" do
    it "should accept a boolean for whether a template is local or remote" do
      @resource.local(true)
      @resource.local.should == true
    end

    it "should default to false" do
      @resource.local.should == false
    end
  end
  
end
