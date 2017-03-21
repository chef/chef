#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2017, Chef Software Inc.
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
      allow(node).to receive(:[]).with(:os).and_return("linux")
      allow(node).to receive(:[]).with(:platform_family).and_return("debian")
      expect(node_map.get(node, :thing)).to eql(nil)
    end
  end

  describe "with a block doing platform_version checks" do
    before do
      node_map.set(:thing, :foo, platform_family: "rhel") do |node|
        node[:platform_version].to_i >= 7
      end
    end

    it "returns the value when the node matches" do
      allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
      allow(node).to receive(:[]).with(:platform_version).and_return("7.0")
      expect(node_map.get(node, :thing)).to eql(:foo)
    end

    it "returns nil when the block does not match" do
      allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
      allow(node).to receive(:[]).with(:platform_version).and_return("6.4")
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    it "returns nil when the platform_family filter does not match" do
      allow(node).to receive(:[]).with(:platform_family).and_return("debian")
      allow(node).to receive(:[]).with(:platform_version).and_return("7.0")
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    it "returns nil when both do not match" do
      allow(node).to receive(:[]).with(:platform_family).and_return("debian")
      allow(node).to receive(:[]).with(:platform_version).and_return("6.0")
      expect(node_map.get(node, :thing)).to eql(nil)
    end

    context "when there is a less specific definition" do
      before do
        node_map.set(:thing, :bar, platform_family: "rhel")
      end

      it "returns the value when the node matches" do
        allow(node).to receive(:[]).with(:platform_family).and_return("rhel")
        allow(node).to receive(:[]).with(:platform_version).and_return("7.0")
        expect(node_map.get(node, :thing)).to eql(:foo)
      end
    end
  end

end
