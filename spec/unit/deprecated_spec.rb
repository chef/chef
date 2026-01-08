#
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
require "chef/deprecated"

describe Chef::Deprecated do
  class TestDeprecation < Chef::Deprecated::Base
    target 999, "test"
  end

  context "loading a deprecation class" do
    it "loads the correct class" do
      expect(Chef::Deprecated.create(:test_deprecation, nil, nil)).to be_an_instance_of(TestDeprecation)
    end

    it "sets a message" do
      deprecation = Chef::Deprecated.create(:test_deprecation, "A test message", nil)
      expect(deprecation.message).to eql("A test message")
    end

    it "sets the location" do
      deprecation = Chef::Deprecated.create(:test_deprecation, nil, "A test location")
      expect(deprecation.location).to eql("A test location")
    end
  end

  context "formatting deprecation warnings" do
    let(:message) { "A test message" }
    let(:location) { "the location" }

    it "displays the full URL" do
      expect(TestDeprecation.new.url).to eql("https://docs.chef.io/deprecations_test/")
    end

    it "formats a complete deprecation message" do
      expect(TestDeprecation.new(message, location).to_s).to eql("Deprecation CHEF-999 from the location\n\n  A test message\n\nPlease see https://docs.chef.io/deprecations_test/ for further details and information on how to correct this problem.")
    end
  end

  it "has no overlapping deprecation IDs" do
    id_map = {}
    ObjectSpace.each_object(Class).select { |cls| cls < Chef::Deprecated::Base }.each do |cls|
      (id_map[cls.deprecation_id] ||= []) << cls
    end
    collisions = id_map.select { |k, v| v.size != 1 }
    unless collisions.empty?
      raise "Found deprecation ID collisions:\n#{collisions.map { |k, v| "* #{k} #{v.map(&:name).join(", ")}" }.join("\n")}"
    end
  end
end
