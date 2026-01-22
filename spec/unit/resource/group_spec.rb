#
# Author:: AJ Christensen (<aj@junglistheavy.industries>)
# Author:: Tyler Cloke (<tyler@chef.io>);
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  it "sets the resource_name to :group" do
    expect(resource.resource_name).to eql(:group)
  end

  it "the group_name property is the name_property" do
    expect(resource.group_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :create, :manage, :modify, :remove actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :manage }.not_to raise_error
    expect { resource.action :modify }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "defaults gid to nil" do
    expect(resource.gid).to eql(nil)
  end

  it "defaults members to an empty array" do
    expect(resource.members).to eql([])
  end

  it "defaults comment to be nil" do
    expect(resource.comment).to eql(nil)
  end

  it "aliases users to members, also an empty array" do
    expect(resource.users).to eql([])
  end

  it "accepts domain groups (@ or  separator) on non-windows" do
    expect { resource.group_name "domain@group" }.not_to raise_error
    expect(resource.group_name).to eq("domain@group")
    expect { resource.group_name "domain\\group" }.not_to raise_error
    expect(resource.group_name).to eq("domain\\group")
    expect { resource.group_name "domain\\group^name" }.not_to raise_error
    expect(resource.group_name).to eq("domain\\group^name")
  end
end

describe Chef::Resource::Group, "group_name" do
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  it "allows a string" do
    resource.group_name "pirates"
    expect(resource.group_name).to eql("pirates")
  end

  it "does not allow a hash" do
    expect { resource.send(:group_name, { some_other_user: "is freakin awesome" }) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "gid" do
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  it "allows an integer" do
    resource.gid 100
    expect(resource.gid).to eql(100)
  end

  it "does not allow a hash" do
    expect { resource.send(:gid, { some_other_user: "is freakin awesome" }) }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::Group, "members" do
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  %i{users members}.each do |method|
    it "(#{method}) allows a String and coerces it to an Array" do
      resource.send(method, "some_user")
      expect(resource.send(method)).to eql(["some_user"])
    end

    it "(#{method}) coerces a comma separated list of users to an Array" do
      resource.send(method, "some_user, other_user ,another_user,just_one_more_user")
      expect(resource.send(method)).to eql( %w{some_user other_user another_user just_one_more_user} )
    end

    it "(#{method}) allows an Array" do
      resource.send(method, %w{some_user other_user})
      expect(resource.send(method)).to eql( %w{some_user other_user} )
    end

    it "(#{method}) does not allow a Hash" do
      expect { resource.send(method, { some_user: "is freakin awesome" }) }.to raise_error(NoMethodError)
    end
  end
end

describe Chef::Resource::Group, "append" do
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  it "defaults to false" do
    expect(resource.append).to eql(false)
  end

  it "allows a boolean" do
    resource.append true
    expect(resource.append).to eql(true)
  end

  it "does not allow a hash" do
    expect { resource.send(:gid, { some_other_user: "is freakin awesome" }) }.to raise_error(ArgumentError)
  end

  describe "when it has members" do
    before do
      resource.group_name("pokemon")
      resource.members(%w{blastoise pikachu})
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:members]).to eql(%w{blastoise pikachu})
    end

    it "returns the group name as its identity" do
      expect(resource.identity).to eq("pokemon")
    end
  end
end

describe Chef::Resource::Group, "comment" do
  let(:resource) { Chef::Resource::Group.new("fakey_fakerton") }

  it "allows an string" do
    resource.comment "this is a group comment"
    expect(resource.comment).to eql("this is a group comment")
  end

  it "does not allow a hash" do
    expect { resource.send(:comment, { some_other_user: "is freakin awesome" }) }.to raise_error(ArgumentError)
  end
end
