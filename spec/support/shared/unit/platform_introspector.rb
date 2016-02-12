#
# Author:: Seth Falcon (<seth@chef.io>)
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

shared_examples_for "a platform introspector" do
  before(:each) do
    @platform_hash = {}
    %w{openbsd freebsd}.each do |x|
      @platform_hash[x] = {
        "default" => x,
        "1.2.3" => "#{x}-1.2.3",
      }
    end
    @platform_hash["debian"] = { %w{5 6} => "debian-5/6", "default" => "debian" }
    @platform_hash["default"] = "default"
    # The following @platform_hash keys are used for testing version constraints
    @platform_hash["exact_match"] = { "1.2.3" => "exact", ">= 1.0" => "not exact" }
    @platform_hash["multiple_matches"] = { "~> 2.3.4" => "matched ~> 2.3.4", ">= 2.3" => "matched >=2.3" }
    @platform_hash["invalid_cookbook_version"] = { ">= 21" => "Matches a single number" }
    @platform_hash["successful_matches"] = { "< 3.0" => "matched < 3.0", ">= 3.0" => "matched >= 3.0" }

    @platform_family_hash = {
      "debian" => "debian value",
      [:rhel, :fedora] => "redhatty value",
      "suse" => "suse value",
      :default => "default value",
    }
  end

  it "returns a default value when there is no known platform" do
    node = Hash.new
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("default")
  end

  it "returns a default value when there is no known platform family" do
    expect(platform_introspector.value_for_platform_family(@platform_family_hash)).to eq("default value")
  end

  it "returns a default value when the current platform doesn't match" do
    node.automatic_attrs[:platform] = "not-a-known-platform"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("default")
  end

  it "returns a default value when current platform_family doesn't match" do
    node.automatic_attrs[:platform_family] = "ultra-derived-linux"
    expect(platform_introspector.value_for_platform_family(@platform_family_hash)).to eq("default value")
  end

  it "returns a value based on the current platform" do
    node.automatic_attrs[:platform] = "openbsd"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("openbsd")
  end

  it "returns a value based on the current platform family" do
    node.automatic_attrs[:platform_family] = "debian"
    expect(platform_introspector.value_for_platform_family(@platform_family_hash)).to eq("debian value")
  end

  it "returns a version-specific value based on the current platform" do
    node.automatic_attrs[:platform] = "openbsd"
    node.automatic_attrs[:platform_version] = "1.2.3"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("openbsd-1.2.3")
  end

  it "returns a value based on the current platform if version not found" do
    node.automatic_attrs[:platform] = "openbsd"
    node.automatic_attrs[:platform_version] = "0.0.0"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("openbsd")
  end

  it "returns the exact match" do
    node.automatic_attrs[:platform] = "exact_match"
    node.automatic_attrs[:platform_version] = "1.2.3"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("exact")
  end

  it "raises RuntimeError" do
    node.automatic_attrs[:platform] = "multiple_matches"
    node.automatic_attrs[:platform_version] = "2.3.4"
    expect { platform_introspector.value_for_platform(@platform_hash) }.to raise_error(RuntimeError)
  end

  it "should not require .0 to match >= 21.0" do
    node.automatic_attrs[:platform] = "invalid_cookbook_version"
    node.automatic_attrs[:platform_version] = "21"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("Matches a single number")
  end

  it "should return the value for that match" do
    node.automatic_attrs[:platform] = "successful_matches"
    node.automatic_attrs[:platform_version] = "2.9"
    expect(platform_introspector.value_for_platform(@platform_hash)).to eq("matched < 3.0")
  end

  describe "when platform versions is an array" do
    it "returns a version-specific value based on the current platform" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "6"
      expect(platform_introspector.value_for_platform(@platform_hash)).to eq("debian-5/6")
    end

    it "returns a value based on the current platform if version not found" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "0.0.0"
      expect(platform_introspector.value_for_platform(@platform_hash)).to eq("debian")
    end
  end

  describe "when checking platform?" do

    it "returns true if the node is a provided platform and platforms are provided as symbols" do
      node.automatic_attrs[:platform] = "ubuntu"
      expect(platform_introspector.platform?([:redhat, :ubuntu])).to eq(true)
    end

    it "returns true if the node is a provided platform and platforms are provided as strings" do
      node.automatic_attrs[:platform] = "ubuntu"
      expect(platform_introspector.platform?(%w{redhat ubuntu})).to eq(true)
    end

    it "returns false if the node is not of the provided platforms" do
      node.automatic_attrs[:platform] = "ubuntu"
      expect(platform_introspector.platform?(:splatlinux)).to eq(false)
    end
  end

  describe "when checking platform_family?" do

    it "returns true if the node is in a provided platform family and families are provided as symbols" do
      node.automatic_attrs[:platform_family] = "debian"
      expect(platform_introspector.platform_family?([:rhel, :debian])).to eq(true)
    end

    it "returns true if the node is a provided platform and platforms are provided as strings" do
      node.automatic_attrs[:platform_family] = "rhel"
      expect(platform_introspector.platform_family?(%w{rhel debian})).to eq(true)
    end

    it "returns false if the node is not of the provided platforms" do
      node.automatic_attrs[:platform_family] = "suse"
      expect(platform_introspector.platform_family?(:splatlinux)).to eq(false)
    end

    it "returns false if the node is not of the provided platforms and platform_family is not set" do
      expect(platform_introspector.platform_family?(:splatlinux)).to eq(false)
    end

  end
  # NOTE: this is a regression test for bug CHEF-1514
  describe "when the value is an array" do
    before do
      @platform_hash = {
        "debian" => { "4.0" => [ :restart, :reload ], "default" => [ :restart, :reload, :status ] },
        "ubuntu" => { "default" => [ :restart, :reload, :status ] },
        "centos" => { "default" => [ :restart, :reload, :status ] },
        "redhat" => { "default" => [ :restart, :reload, :status ] },
        "fedora" => { "default" => [ :restart, :reload, :status ] },
        "default" => { "default" => [:restart, :reload ] } }
    end

    it "returns the correct default for a given platform" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "9000"
      expect(platform_introspector.value_for_platform(@platform_hash)).to eq([ :restart, :reload, :status ])
    end

    it "returns the correct platform+version specific value " do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "4.0"
      expect(platform_introspector.value_for_platform(@platform_hash)).to eq([:restart, :reload])
    end
  end

end
