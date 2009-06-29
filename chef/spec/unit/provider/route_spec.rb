#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
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

describe Chef::Provider::Route, "initialize" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource", :null_object => true)
  end

  it "should return a Chef::Provider::Route object" do
    provider = Chef::Provider::Route.new(@node, @new_resource)
    provider.should be_a_kind_of(Chef::Provider::Route)
  end

end

describe Chef::Provider::Route, "action_add" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Route",
      :null_object => true,
      :name => "10.0.0.10",
      :target => "10.0.0.10",
      :gateway => "10.0.0.9"
    )
    @current_resource = mock("Chef::Resource::Route",
      :null_object => true,
      :name => "10.0.0.10",
      :target => "10.0.0.10",
      :gateway => "10.0.0.9"
    )

    @provider = Chef::Provider::Route.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should add the route if it does not exist" do
    @provider.stub!(:run_command).and_return(true)
    @current_resource.stub!(:gateway).and_return(nil)
    @new_resource.should_receive(:updated=).with(true)
    @provider.action_add
  end

  it "should not add the route if it exists" do
    @provider.stub!(:run_command).and_return(true)
    @new_resource.should_not_receive(:updated=).with(true)
    @provider.action_add
  end
end

describe Chef::Provider::Route, "action_delete" do
  before(:each) do
    @node = mock("Chef::Node", :null_object => true)
    @new_resource = mock("Chef::Resource::Route",
      :null_object => true,
      :name => "10.0.0.10",
      :target => "10.0.0.10",
      :gateway => "10.0.0.9"
    )
    @current_resource = mock("Chef::Resource::Route",
      :null_object => true,
      :name => "10.0.0.10",
      :target => "10.0.0.10",
      :gateway => "10.0.0.9"
    )

    @provider = Chef::Provider::Route.new(@node, @new_resource)
    @provider.current_resource = @current_resource
  end

  it "should delete the route if it exists" do
    @provider.stub!(:run_command).and_return(true)
    @new_resource.should_receive(:updated=).with(true)
    @provider.action_delete
  end

  it "should not delete the route if it does not exist" do
    @current_resource.stub!(:gateway).and_return(nil)
    @provider.stub!(:run_command).and_return(true)
    @new_resource.should_not_receive(:updated=).with(true)
    @provider.action_delete
  end
end
