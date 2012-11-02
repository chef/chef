#
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010, 2012 Opscode, Inc.
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
        "1.2.3" => "#{x}-1.2.3"
      }
    end
    @platform_hash["debian"] = {["5", "6"] => "debian-5/6", "default" => "debian"}
    @platform_hash["default"] = "default"

    @platform_family_hash = {
      "debian" => "debian value",
      [:rhel, :fedora] => "redhatty value",
      "suse" => "suse value",
      :default => "default value"
    }
  end

  it "returns a default value when there is no known platform" do
    node = Hash.new
    platform_introspector.value_for_platform(@platform_hash).should == "default"
  end

  it "returns a default value when there is no known platform family" do
    platform_introspector.value_for_platform_family(@platform_family_hash).should == "default value"
  end

  it "returns a default value when the current platform doesn't match" do
    node.automatic_attrs[:platform] = "not-a-known-platform"
    platform_introspector.value_for_platform(@platform_hash).should == "default"
  end

  it "returns a default value when current platform_family doesn't match" do
    node.automatic_attrs[:platform_family] = "ultra-derived-linux"
    platform_introspector.value_for_platform_family(@platform_family_hash).should == "default value"
  end

  it "returns a value based on the current platform" do
    node.automatic_attrs[:platform] = "openbsd"
    platform_introspector.value_for_platform(@platform_hash).should == "openbsd"
  end

  it "returns a value based on the current platform family" do
    node.automatic_attrs[:platform_family] = "debian"
    platform_introspector.value_for_platform_family(@platform_family_hash).should == "debian value"
  end

  it "returns a version-specific value based on the current platform" do
    node.automatic_attrs[:platform] = "openbsd"
    node.automatic_attrs[:platform_version] = "1.2.3"
    platform_introspector.value_for_platform(@platform_hash).should == "openbsd-1.2.3"
  end

  it "returns a value based on the current platform if version not found" do
    node.automatic_attrs[:platform] = "openbsd"
    node.automatic_attrs[:platform_version] = "0.0.0"
    platform_introspector.value_for_platform(@platform_hash).should == "openbsd"
  end

  describe "when platform versions is an array" do
    it "returns a version-specific value based on the current platform" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "6"
      platform_introspector.value_for_platform(@platform_hash).should == "debian-5/6"
    end

    it "returns a value based on the current platform if version not found" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = "0.0.0"
      platform_introspector.value_for_platform(@platform_hash).should == "debian"
    end
  end

  describe "when checking platform?" do

    it "returns true if the node is a provided platform and platforms are provided as symbols" do
      node.automatic_attrs[:platform] = 'ubuntu'
      platform_introspector.platform?([:redhat, :ubuntu]).should == true
    end

    it "returns true if the node is a provided platform and platforms are provided as strings" do
      node.automatic_attrs[:platform] = 'ubuntu'
      platform_introspector.platform?(["redhat", "ubuntu"]).should == true
    end

    it "returns false if the node is not of the provided platforms" do
      node.automatic_attrs[:platform] = 'ubuntu'
      platform_introspector.platform?(:splatlinux).should == false
    end
  end

  describe "when checking platform_family?" do

    it "returns true if the node is in a provided platform family and families are provided as symbols" do
      node.automatic_attrs[:platform_family] = 'debian'
      platform_introspector.platform_family?([:rhel, :debian]).should == true
    end

    it "returns true if the node is a provided platform and platforms are provided as strings" do
      node.automatic_attrs[:platform_family] = 'rhel'
      platform_introspector.platform_family?(["rhel", "debian"]).should == true
    end

    it "returns false if the node is not of the provided platforms" do
      node.automatic_attrs[:platform_family] = 'suse'
      platform_introspector.platform_family?(:splatlinux).should == false
    end

    it "returns false if the node is not of the provided platforms and platform_family is not set" do
      platform_introspector.platform_family?(:splatlinux).should == false
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
        "default" => { "default" => [:restart, :reload ] }}
    end

    it "returns the correct default for a given platform" do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = '9000'
      platform_introspector.value_for_platform(@platform_hash).should == [ :restart, :reload, :status ]
    end

    it "returns the correct platform+version specific value " do
      node.automatic_attrs[:platform] = "debian"
      node.automatic_attrs[:platform_version] = '4.0'
      platform_introspector.value_for_platform(@platform_hash).should == [:restart, :reload]
    end
  end

end

