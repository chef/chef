#
# Author:: Adam Jacob (<adam@chef.io>)
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

describe Chef::Resource::User, "initialize" do
  let(:resource) { Chef::Resource::User.new("notarealuser") }

  it "sets the resource_name to nil" do
    expect(resource.resource_name).to eql(nil)
  end

  it "username property is the name property" do
    expect(resource.username).to eql("notarealuser")
  end

  %w{comment uid gid home shell password}.each do |prop|
    it "sets #{prop} to nil" do
      expect(resource.send(prop)).to eql(nil)
    end
  end

  it "sets action to :create" do
    expect(resource.action).to eql([:create])
  end

  %w{manage_home non_unique force system}.each do |prop|
    it "sets #{prop} to false" do
      expect(resource.send(prop)).to eql(false)
    end
  end

  %w{create remove modify manage lock unlock}.each do |action|
    it "allows action #{action}" do
      expect(resource.allowed_actions.detect { |a| a == action.to_sym }).to eql(action.to_sym)
    end
  end

  it "group is an alias for the gid property" do
    resource.group(1234)
    expect(resource.gid).to eql(1234)
  end

  it "accepts domain users (@ or  separator) on non-windows" do
    expect { resource.username "domain@user" }.not_to raise_error
    expect(resource.username).to eq("domain@user")
    expect { resource.username "domain\\user" }.not_to raise_error
    expect(resource.username).to eq("domain\\user")
  end
end

%w{username comment home shell password}.each do |attrib|
  describe Chef::Resource::User, attrib do
    let(:resource) { Chef::Resource::User.new("notarealuser") }

    it "allows a string" do
      resource.send(attrib, "something")
      expect(resource.send(attrib)).to eql("something")
    end

    it "does not allow a hash" do
      expect { resource.send(attrib, { woot: "i found it" }) }.to raise_error(ArgumentError)
    end
  end
end

%w{uid gid}.each do |attrib|
  describe Chef::Resource::User, attrib do
    let(:resource) { Chef::Resource::User.new("notarealuser") }

    it "allows a string" do
      resource.send(attrib, "100")
      expect(resource.send(attrib)).to eql("100")
    end

    it "allows an integer" do
      resource.send(attrib, 100)
      expect(resource.send(attrib)).to eql(100)
    end

    it "does not allow a hash" do
      expect { resource.send(attrib, { woot: "i found it" }) }.to raise_error(ArgumentError)
    end
  end

  describe "when it has uid, gid, and home" do
    let(:resource) { Chef::Resource::User.new("root") }

    before do
      resource.uid(123)
      resource.gid(456)
      resource.home("/usr/local/root/")
    end

    it "describes its state" do
      state = resource.state_for_resource_reporter
      expect(state[:uid]).to eq(123)
      expect(state[:gid]).to eq(456)
      expect(state[:home]).to eq("/usr/local/root/")
    end

    it "returns the username as its identity" do
      expect(resource.identity).to eq("root")
    end
  end
end
