#
# Author:: AJ Christensen (<aj@opscode.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

describe Chef::Resource::RubyBlock do

  before(:each) do
    @resource = Chef::Resource::RubyBlock.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::RubyBlock" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::RubyBlock)
  end

  it "should have a default action of 'create'" do
    @resource.action.should eql("run")
  end
  
  it "should have a resource name of :ruby_block" do
    @resource.resource_name.should eql(:ruby_block)
  end

  it "should accept a ruby block/proc/.. for the 'block' parameter" do
    @resource.block do
      "foo"
    end.call.should eql("foo")
  end

  it "allows the action to be 'create'" do
    @resource.action :create
    @resource.action.should == [:create]
  end

  describe "when it has been initialized with block code" do
    before do 
      @resource.block_name("puts 'harrrr'")
    end

    it "returns the block as its identity" do
      @resource.identity.should == "puts 'harrrr'"
    end
  end
end
