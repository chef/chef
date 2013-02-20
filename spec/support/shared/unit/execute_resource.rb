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

shared_examples_for "an execute resource" do

  before(:each) do
    @resource = execute_resource
  end

  it "should create a new Chef::Resource::Execute" do
    @resource.should be_a_kind_of(Chef::Resource)
    @resource.should be_a_kind_of(Chef::Resource::Execute)
  end

  it "should set the command to the first argument to new" do
    @resource.command.should eql(resource_instance_name)
  end

  it "should accept an array on instantiation, too" do
    resource = Chef::Resource::Execute.new(%w{something else})
    resource.should be_a_kind_of(Chef::Resource)
    resource.should be_a_kind_of(Chef::Resource::Execute)
    resource.command.should eql(%w{something else})
  end

  it "should accept a string for the command to run" do
    @resource.command "something"
    @resource.command.should eql("something")
  end

  it "should accept an array for the command to run" do
    @resource.command %w{something else}
    @resource.command.should eql(%w{something else})
  end

  it "should accept a string for the cwd" do
    @resource.cwd "something"
    @resource.cwd.should eql("something")
  end

  it "should accept a hash for the environment" do
    test_hash = { :one => :two }
    @resource.environment(test_hash)
    @resource.environment.should eql(test_hash)
  end

  it "allows the environment to be specified with #env" do
    @resource.should respond_to(:env)
  end

  it "should accept a string for the group" do
    @resource.group "something"
    @resource.group.should eql("something")
  end

  it "should accept an integer for the group" do
    @resource.group 1
    @resource.group.should eql(1)
  end

  it "should accept an array for the execution path" do
    @resource.path ["woot"]
    @resource.path.should eql(["woot"])
  end

  it "should accept an integer for the return code" do
    @resource.returns 1
    @resource.returns.should eql(1)
  end

  it "should accept an integer for the timeout" do
    @resource.timeout 1
    @resource.timeout.should eql(1)
  end

  it "should accept a string for the user" do
    @resource.user "something"
    @resource.user.should eql("something")
  end

  it "should accept an integer for the user" do
    @resource.user 1
    @resource.user.should eql(1)
  end

  it "should accept a string for creates" do
    @resource.creates "something"
    @resource.creates.should eql("something")
  end

  describe "when it has cwd, environment, group, path, return value, and a user" do
    before do
      @resource.command("grep")
      @resource.cwd("/tmp/")
      @resource.environment({ :one => :two })
      @resource.group("legos")
      @resource.path(["/var/local/"])
      @resource.returns(1)
      @resource.user("root")
    end

    it "returns the command as its identity" do
      @resource.identity.should == "grep"
    end
  end
end

