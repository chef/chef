#
# Author:: Adam Jacob (<adam@opscode.com>)
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

shared_examples_for "a script resource" do

  before(:each) do
    @resource = script_resource
  end  

  it "should create a new Chef::Resource::Script" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Script)
  end
  
  it "should have a resource name of :script" do
    @resource.resource_name.should eql(resource_name)
  end
  
  it "should set command to the argument provided to new" do
    @resource.command.should eql(resource_instance_name)
  end
  
  it "should accept a string for the code" do
    @resource.code "hey jude"
    @resource.code.should eql("hey jude")
  end
  
  it "should accept a string for the flags" do
    @resource.flags "-f"
    @resource.flags.should eql("-f")
  end

end

