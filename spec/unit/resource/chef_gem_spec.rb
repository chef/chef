#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2008, 2012 Opscode, Inc.
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

describe Chef::Resource::ChefGem, "initialize" do
  
  before(:each) do
    @resource = Chef::Resource::ChefGem.new("foo")
  end
  
  it "should return a Chef::Resource::ChefGem" do
    @resource.should be_a_kind_of(Chef::Resource::ChefGem)
  end
  
  it "should set the resource_name to :chef_gem" do
    @resource.resource_name.should eql(:chef_gem)
  end
  
  it "should set the provider to Chef::Provider::Package::Rubygems" do
    @resource.provider.should eql(Chef::Provider::Package::Rubygems)
  end
end

describe Chef::Resource::ChefGem, "gem_binary" do
  before(:each) do
    @resource = Chef::Resource::ChefGem.new("foo")
  end

  it "should raise an exception when gem_binary is set" do
    lambda { @resource.gem_binary("/lol/cats/gem") }.should raise_error(ArgumentError)
  end
end
