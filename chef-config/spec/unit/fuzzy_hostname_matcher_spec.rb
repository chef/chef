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

require "spec_helper"
require "chef-config/mixin/fuzzy_hostname_matcher"

RSpec.describe ChefConfig::Mixin::FuzzyHostnameMatcher do
  let(:matcher) do
    Class.new { include ChefConfig::Mixin::FuzzyHostnameMatcher }.new
  end

  describe "#fuzzy_hostname_match?" do
    it "matches a hostname with a wildcard pattern" do
      expect(matcher.fuzzy_hostname_match?("foo.example.com", "example.com")).to be true
    end

    it "does not match unrelated hostnames" do
      expect(matcher.fuzzy_hostname_match?("foo.example.com", "other.com")).to be false
    end

    it "returns false for bare IPv6 addresses instead of raising" do
      expect(matcher.fuzzy_hostname_match?("2001:db8::1", "example.com")).to be false
    end

    it "returns false for bracketed IPv6 addresses instead of raising" do
      expect(matcher.fuzzy_hostname_match?("[2001:db8::1]", "example.com")).to be false
    end

    it "returns false for IPv6 URLs instead of raising" do
      expect(matcher.fuzzy_hostname_match?("https://[2001:db8::1]/path", "example.com")).to be false
    end
  end

  describe "#fuzzy_hostname_match_any?" do
    it "returns false when hostname is nil" do
      expect(matcher.fuzzy_hostname_match_any?(nil, "example.com")).to be false
    end

    it "returns false when matches is nil" do
      expect(matcher.fuzzy_hostname_match_any?("foo.example.com", nil)).to be false
    end

    it "matches against comma-separated patterns" do
      expect(matcher.fuzzy_hostname_match_any?("foo.example.com", "other.com, example.com")).to be true
    end

    it "returns false for IPv6 URLs with hostname no_proxy patterns" do
      ipv6_url = "https://[2001:db8:abcd:ef01::1]/organizations/o3"
      no_proxy = "gateway.example.net,internal.example.com"
      expect(matcher.fuzzy_hostname_match_any?(ipv6_url, no_proxy)).to be false
    end

    it "returns false for bare IPv6 with hostname no_proxy patterns" do
      expect(matcher.fuzzy_hostname_match_any?("2001:db8::1", "example.com,other.net")).to be false
    end
  end
end
