#
# Author:: Lamont Granquist (<lamont@chef.io>)
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
require "chef/node_map"

class Foo; end
class Bar; end

class FooResource < Chef::Resource; end
class BarResource < Chef::Resource; end

class FooProvider < Chef::Provider; end
class BarProvider < Chef::Provider; end

describe Chef::NodeMap do

  let(:node_map) { Chef::NodeMap.new }

  let(:node) { Chef::Node.new }

  describe "with a bad filter name" do
    it "should raise an error" do
      expect { node_map.set(node, :thing, on_platform_family: "rhel") }.to raise_error(ArgumentError)
    end
  end

  describe "when no matchers are set at all" do
    before do
      node_map.set(:thing, :foo)
    end

    it "returns the value" do
      expect(node_map.get(node, :thing)).to eql(:foo)
    end

    it "returns nil for keys that do not exist" do
      expect(node_map.get(node, :other_thing)).to eql(nil)
    end
  end

  describe "filtering by os" do
    before do
      node_map.set(:thing, :foo, os: ["windows"])
      node_map.set(:thing, :bar, os: "linux")
    end
    it "returns the correct value for windows" do
      allow(node).to receive(:[]).with(:os).and_return("windows")
      expect(node_map.get(node, :thing)).to eql(:foo)
    end
    it "returns the correct value for linux" do
      allow(node).to receive(:[]).with(:os).and_return("linux")
      expect(node_map.get(node, :thing)).to eql(:bar)
    end
    it "returns nil for a non-matching os" do
      allow(node).to receive(:[]).with(:os).and_return("freebsd")
      expect(node_map.get(node, :thing)).to eql(nil)
    end
  end

  describe "rejecting an os" do
    before do
      node_map.set(:thing, :foo, os: "!windows")
    end
    it "returns nil for windows" do
      allow(node).to receive(:[]).with(:os).and_return("windows")
      expect(node_map.get(node, :thing)).to eql(nil)
    end
    it "returns the correct value for linux" do
      allow(node).to receive(:[]).with(:os).and_return("linux")
      expect(node_map.get(node, :thing)).to eql(:foo)
    end
  end

  describe "filtering by os and platform_family" do
    before do
      node_map.set(:thing, :bar, os: "linux", platform_family: "rhel")
    end

    it "returns the correct value when both match" do
      allow(node).to receive(:[]).with(:os).and_return("linux")
      allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
      expect(node_map.get(node, :thing)).to eql(:bar)
    end

    it "returns nil for a non-matching os" do
      allow(node).to receive(:[]).with(:os).and_return("freebsd")
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    it "returns nil when the platform_family does not match" do
      node.automatic["os"] = "linux"
      node.automatic["platform_family"] = "debian"
      expect(node_map.get(node, :thing)).to eql(nil)
    end
  end

  describe "platform version checks" do
    before do
      node_map.set(:thing, :foo, platform_family: "rhel", platform_version: ">= 7")
    end

    it "handles non-x.y.z platform versions without throwing an exception" do
      allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
      allow(node).to receive(:[]).with(:platform_version).and_return("7.19.2.2F")
      expect(node_map.get(node, :thing)).to eql(:foo)
    end

    it "handles non-x.y.z platform versions without throwing an exception when the match fails" do
      allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
      allow(node).to receive(:[]).with(:platform_version).and_return("4.19.2.2F")
      expect(node_map.get(node, :thing)).to eql(nil)
    end
  end

  describe "ordering classes" do
    it "last writer wins when its reverse alphabetic order" do
      node_map.set(:thing, Foo)
      node_map.set(:thing, Bar)
      expect(node_map.get(node, :thing)).to eql(Bar)
    end

    it "last writer wins when its alphabetic order" do
      node_map.set(:thing, Bar)
      node_map.set(:thing, Foo)
      expect(node_map.get(node, :thing)).to eql(Foo)
    end
  end

  describe "deleting classes" do
    it "deletes a class and removes the mapping completely" do
      node_map.set(:thing, Bar)
      expect( node_map.delete_class(Bar) ).to include({ thing: [{ klass: Bar, target_mode: nil, agent_mode: true }] })
      expect( node_map.get(node, :thing) ).to eql(nil)
    end

    it "deletes a class and leaves the mapping that still has an entry" do
      node_map.set(:thing, Bar)
      node_map.set(:thing, Foo)
      expect( node_map.delete_class(Bar) ).to eql({ thing: [{ klass: Bar, target_mode: nil, agent_mode: true }] })
      expect( node_map.get(node, :thing) ).to eql(Foo)
    end

    it "handles deleting classes from multiple keys" do
      node_map.set(:thing1, Bar)
      node_map.set(:thing2, Bar)
      node_map.set(:thing2, Foo)
      expect( node_map.delete_class(Bar) ).to eql({ thing1: [{ klass: Bar, target_mode: nil, agent_mode: true }], thing2: [{ klass: Bar, target_mode: nil, agent_mode: true }] })
      expect( node_map.get(node, :thing1) ).to eql(nil)
      expect( node_map.get(node, :thing2) ).to eql(Foo)
    end
  end

  describe "with a block doing platform_version checks" do
    before do
      node_map.set(:thing, :foo, platform_family: "rhel") do |node|
        node[:platform_version].to_i >= 7
      end
    end

    it "returns the value when the node matches" do
      node.automatic["platform_family"] = "rhel"
      node.automatic["platform_version"] = "7.0"
      expect(node_map.get(node, :thing)).to eql(:foo)
    end

    it "returns nil when the block does not match" do
      node.automatic["platform_family"] = "rhel"
      node.automatic["platform_version"] = "6.4"
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    it "returns nil when the platform_family filter does not match" do
      node.automatic["platform_family"] = "debian"
      node.automatic["platform_version"] = "7.0"
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    it "returns nil when both do not match" do
      node.automatic["platform_family"] = "debian"
      node.automatic["platform_version"] = "6.0"
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    context "when there is a less specific definition" do
      before do
        node_map.set(:thing, :bar, platform_family: "rhel")
      end

      it "returns the value when the node matches" do
        node.automatic["platform_family"] = "rhel"
        node.automatic["platform_version"] = "7.0"
        expect(node_map.get(node, :thing)).to eql(:foo)
      end
    end
  end

  # When in target mode, only match when target_mode is explicitly supported
  context "when target mode is enabled" do
    before do
      allow(Chef::Config).to receive(:target_mode?).and_return(true)
    end

    it "returns the value when target_mode matches" do
      node_map.set(:something, :network, target_mode: true)
      expect(node_map.get(node, :something)).to eql(:network)
    end

    it "returns nil when target_mode does not match" do
      node_map.set(:something, :local, target_mode: false)
      expect(node_map.get(node, :something)).to eql(nil)
    end
  end

  # When not in target mode, match regardless of target_mode filter
  context "when target mode is not enabled" do
    before do
      allow(Chef::Config).to receive(:target_mode?).and_return(false)
    end

    it "returns the value if target_mode matches" do
      node_map.set(:something, :local, target_mode: true)
      expect(node_map.get(node, :something)).to eql(:local)
    end

    it "returns the value if target_mode does not match" do
      node_map.set(:something, :local, target_mode: false)
      expect(node_map.get(node, :something)).to eql(:local)
    end
  end

  describe "locked mode" do
    context "while unlocked" do
      it "allows setting the same key twice" do
        expect(Chef::Log).to_not receive(:warn)
        node_map.set(:foo, FooResource)
        node_map.set(:foo, BarResource)
        expect(node_map.get(node, :foo)).to eql(BarResource)
      end
    end

    context "while locked" do
      it "warns on setting the same key twice" do
        expect(Chef::Log).to receive(:warn).with(/Resource foo/)
        node_map.set(:foo, FooResource)
        node_map.lock!
        node_map.set(:foo, BarResource)
        expect(node_map.get(node, :foo)).to eql(BarResource)
      end

      it "warns on setting the same key twice for a provider" do
        expect(Chef::Log).to receive(:warn).with(/Provider foo/)
        node_map.set(:foo, FooProvider)
        node_map.lock!
        node_map.set(:foo, BarProvider)
        expect(node_map.get(node, :foo)).to eql(BarProvider)
      end
    end
  end

end
