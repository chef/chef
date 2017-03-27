#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "spec_helper"

shared_examples_for "an execute resource" do

  before(:each) do
    @resource = execute_resource
  end

  it "should create a new Chef::Resource::Execute" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Execute)
  end

  it "should set the command to the first argument to new" do
    expect(@resource.command).to eql(resource_instance_name)
  end

  it "should accept an array on instantiation, too" do
    resource = Chef::Resource::Execute.new(%w{something else})
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::Execute)
    expect(resource.command).to eql(%w{something else})
  end

  it "should accept a string for the command to run" do
    @resource.command "something"
    expect(@resource.command).to eql("something")
  end

  it "should accept an array for the command to run" do
    @resource.command %w{something else}
    expect(@resource.command).to eql(%w{something else})
  end

  it "should accept a string for the cwd" do
    @resource.cwd "something"
    expect(@resource.cwd).to eql("something")
  end

  it "should accept a hash for the environment" do
    test_hash = { :one => :two }
    @resource.environment(test_hash)
    expect(@resource.environment).to eql(test_hash)
  end

  it "allows the environment to be specified with #env" do
    expect(@resource).to respond_to(:env)
  end

  it "should accept a string for the group" do
    @resource.group "something"
    expect(@resource.group).to eql("something")
  end

  it "should accept an integer for the group" do
    @resource.group 1
    expect(@resource.group).to eql(1)
  end

  it "the old path property (that never worked) is not supported in chef >= 13" do
    expect { @resource.path [ "woot" ] }.to raise_error
  end

  it "should accept an integer for the return code" do
    @resource.returns 1
    expect(@resource.returns).to eql(1)
  end

  it "should accept an integer for the timeout" do
    @resource.timeout 1
    expect(@resource.timeout).to eql(1)
  end

  it "should accept a string for the user" do
    @resource.user "something"
    expect(@resource.user).to eql("something")
  end

  it "should accept an integer for the user" do
    @resource.user 1
    expect(@resource.user).to eql(1)
  end

  it "should accept a string for the domain" do
    @resource.domain "mothership"
    expect(@resource.domain).to eql("mothership")
  end

  it "should accept a string for the password" do
    @resource.password "we.funk!"
    expect(@resource.password).to eql("we.funk!")
  end

  it "should accept a string for creates" do
    @resource.creates "something"
    expect(@resource.creates).to eql("something")
  end

  it "should accept a boolean for live streaming" do
    @resource.live_stream true
    expect(@resource.live_stream).to be true
  end

  describe "the resource's sensitive attribute" do
    it "should be false by default" do
      expect(@resource.sensitive).to eq(false)
    end

    it "should be true if set to true" do
      expect(@resource.sensitive).to eq(false)
      @resource.sensitive true
      expect(@resource.sensitive).to eq(true)
    end

    it "should be true if the password is non-nil" do
      @resource.password("we.funk!")
      expect(@resource.sensitive).to eq(true)
    end

    it "should be true if the password is non-nil but the value is explicitly set to false" do
      @resource.password("we.funk!")
      @resource.sensitive false
      expect(@resource.sensitive).to eq(true)
    end

  end

  describe "when it has cwd, environment, group, path, return value, and a user" do
    before do
      @resource.command("grep")
      @resource.cwd("/tmp/")
      @resource.environment({ :one => :two })
      @resource.group("legos")
      @resource.returns(1)
      @resource.user("root")
    end

    it "returns the command as its identity" do
      expect(@resource.identity).to eq("grep")
    end
  end
end
