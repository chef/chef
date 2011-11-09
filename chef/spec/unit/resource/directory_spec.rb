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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))

describe Chef::Resource::Directory do

  before(:each) do
    @resource = Chef::Resource::Directory.new("fakey_fakerton")
  end

  it "should create a new Chef::Resource::Directory" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Directory)
  end

  it "should have a name" do
    @resource.name.should eql("fakey_fakerton")
  end

  it "should have a default action of 'create'" do
    @resource.action.should eql(:create)
  end

  it "should accept create or delete for action" do
    lambda { @resource.action :create }.should_not raise_error(ArgumentError)
    lambda { @resource.action :delete }.should_not raise_error(ArgumentError)
    lambda { @resource.action :blues }.should raise_error(ArgumentError)
  end

  it "should accept a group name or id for group" do
    lambda { @resource.group "root" }.should_not raise_error(ArgumentError)
    lambda { @resource.group 123 }.should_not raise_error(ArgumentError)
    lambda { @resource.group "root*goo" }.should raise_error(ArgumentError)
  end

  it "should accept a valid unix file mode" do
    lambda { @resource.mode 0444 }.should_not raise_error(ArgumentError)
    lambda { @resource.mode 444 }.should_not raise_error(ArgumentError)
    lambda { @resource.mode 4 }.should raise_error(ArgumentError)
  end

  it "should accept a user name or id for owner" do
    lambda { @resource.owner "root" }.should_not raise_error(ArgumentError)
    lambda { @resource.owner 123 }.should_not raise_error(ArgumentError)
    lambda { @resource.owner "root*goo" }.should raise_error(ArgumentError)
  end

  it "should use the object name as the path by default" do
    @resource.path.should eql("fakey_fakerton")
  end

  it "should accept a string as the path" do
    lambda { @resource.path "/tmp" }.should_not raise_error(ArgumentError)
    lambda { @resource.path Hash.new }.should raise_error(ArgumentError)
  end

  it "should allow you to have specify whether the action is recursive with true/false" do
    lambda { @resource.recursive true }.should_not raise_error(ArgumentError)
    lambda { @resource.recursive false }.should_not raise_error(ArgumentError)
    lambda { @resource.recursive "monkey" }.should raise_error(ArgumentError)
  end

end
