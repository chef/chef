#
# Author:: AJ Christensen (<aj@opscode.com>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Group, "initialize" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end  

  it "should create a new Chef::Resource::Group" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Group)
  end

  it "should set the resource_name to :group" do
    @resource.resource_name.should eql(:group)
  end
  
  it "should set the groupname equal to the argument to initialize" do
    @resource.groupname.should eql("admin")
  end

  it "should set gid to nil" do
    @resource.gid.should eql(nil)
  end
  
  it "should set action to :create" do
    @resource.action.should eql(:create)
  end
  
  %w{create remove modify manage}.each do |action|
    it "should allow action #{action}" do
      @resource.allowed_actions.detect { |a| a == action.to_sym }.should eql(action.to_sym)
    end
  end
end
