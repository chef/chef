#
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Tyler Cloke (<tyler@chef.io>);
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

describe Chef::Resource::Group, "initialize" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should create a new Chef::Resource::Group" do
    expect(@resource).to be_a_kind_of(Chef::Resource)
    expect(@resource).to be_a_kind_of(Chef::Resource::Group)
  end

  it "should set the resource_name to :group" do
    expect(@resource.resource_name).to eql(:group)
  end

  it "should set the group_name equal to the argument to initialize" do
    expect(@resource.group_name).to eql("admin")
  end

  it "should default gid to nil" do
    expect(@resource.gid).to eql(nil)
  end

  it "should default members to an empty array" do
    expect(@resource.members).to eql([])
  end

  it "should alias users to members, also an empty array" do
    expect(@resource.users).to eql([])
  end

  it "should set action to :create" do
    expect(@resource.action).to eql([:create])
  end

  %w{create remove modify manage}.each do |action|
    it "should allow action #{action}" do
      expect(@resource.allowed_actions.detect { |a| a == action.to_sym }).to eql(action.to_sym)
    end
  end

  it "should accept domain groups (@ or \ separator) on non-windows" do
    expect { @resource.group_name "domain\@group" }.not_to raise_error
    expect(@resource.group_name).to eq("domain\@group")
    expect { @resource.group_name "domain\\group" }.not_to raise_error
    expect(@resource.group_name).to eq("domain\\group")
    expect { @resource.group_name "domain\\group^name" }.not_to raise_error
    expect(@resource.group_name).to eq("domain\\group^name")
  end
end

describe Chef::Resource::Group, "group_name" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow a string" do
    @resource.group_name "pirates"
    expect(@resource.group_name).to eql("pirates")
  end

  it "should not allow a hash" do
    expect { @resource.send(:group_name, { :aj => "is freakin awesome" }) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "gid" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should allow an integer" do
    @resource.gid 100
    expect(@resource.gid).to eql(100)
  end

  it "should not allow a hash" do
    expect { @resource.send(:gid, { :aj => "is freakin awesome" }) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "members" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  [ :users, :members].each do |method|
    it "(#{method}) should allow and convert a string" do
      @resource.send(method, "aj")
      expect(@resource.send(method)).to eql(["aj"])
    end

    it "(#{method}) should split a string on commas" do
      @resource.send(method, "aj,adam")
      expect(@resource.send(method)).to eql( %w{aj adam} )
    end

    it "(#{method}) should allow an array" do
      @resource.send(method, %w{aj adam})
      expect(@resource.send(method)).to eql( %w{aj adam} )
    end

    it "(#{method}) should not allow a hash" do
      expect { @resource.send(method, { :aj => "is freakin awesome" }) }.to raise_error(ArgumentError)
    end
  end
end

describe Chef::Resource::Group, "append" do
  before(:each) do
    @resource = Chef::Resource::Group.new("admin")
  end

  it "should default to false" do
    expect(@resource.append).to eql(false)
  end

  it "should allow a boolean" do
    @resource.append true
    expect(@resource.append).to eql(true)
  end

  it "should not allow a hash" do
    expect { @resource.send(:gid, { :aj => "is freakin awesome" }) }.to raise_error(ArgumentError)
  end

  describe "when it has members" do
    before do
      @resource.group_name("pokemon")
      @resource.members(%w{blastoise pikachu})
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:members]).to eql(%w{blastoise pikachu})
    end

    it "returns the group name as its identity" do
      expect(@resource.identity).to eq("pokemon")
    end
  end
end
