#
# Author:: Seth Falcon (<seth@chef.io>)
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

require "spec_helper"
require "chef/dsl/platform_introspection"

class LanguageTester
  attr_reader :node
  def initialize(node)
    @node = node
  end
  include Chef::DSL::PlatformIntrospection
end

describe "PlatformIntrospection implementors" do

  let(:node) { Chef::Node.new }
  let(:platform_introspector) { LanguageTester.new(node) }

  it_behaves_like "a platform introspector"

end

describe Chef::DSL::PlatformIntrospection::PlatformDependentValue do
  before do
    platform_hash = {
      :openbsd => { :default => "free, functional, secure" },
      [:redhat, :centos, :fedora, :scientific] => { :default => '"stable"' },
      :ubuntu => { "10.04" => "using upstart more", :default => "using init more" },
      :default => "bork da bork",
    }
    @platform_specific_value = Chef::DSL::PlatformIntrospection::PlatformDependentValue.new(platform_hash)
  end

  it "returns the default value when the platform doesn't match" do
    expect(@platform_specific_value.value_for_node(:platform => :dos)).to eq("bork da bork")
  end

  it "returns a value for a platform set as a group" do
    expect(@platform_specific_value.value_for_node(:platform => :centos)).to eq('"stable"')
  end

  it "returns a value for the platform when it was set as a symbol but fetched as a string" do
    expect(@platform_specific_value.value_for_node(:platform => "centos")).to eq('"stable"')
  end

  it "returns a value for a specific platform version" do
    node = { :platform => "ubuntu", :platform_version => "10.04" }
    expect(@platform_specific_value.value_for_node(node)).to eq("using upstart more")
  end

  it "returns a platform-default value if the platform version doesn't match an explicit one" do
    node = { :platform => "ubuntu", :platform_version => "9.10" }
    expect(@platform_specific_value.value_for_node(node)).to eq("using init more")
  end

  it "returns nil if there is no default and no platforms match" do
    # this matches the behavior in the original implementation.
    # whether or not it's correct is another matter.
    platform_specific_value = Chef::DSL::PlatformIntrospection::PlatformDependentValue.new({})
    expect(platform_specific_value.value_for_node(:platform => "foo")).to be_nil
  end

  it "raises an argument error if the platform hash is not correctly structured" do
    bad_hash = { :ubuntu => :foo } # should be :ubuntu => {:default => 'foo'}
    expect { Chef::DSL::PlatformIntrospection::PlatformDependentValue.new(bad_hash) }.to raise_error(ArgumentError)
  end

end
describe Chef::DSL::PlatformIntrospection::PlatformFamilyDependentValue do
  before do
    @array_values = [:stop, :start, :reload]

    @platform_family_hash = {
      "debian" => "debian value",
      [:rhel, "fedora"] => "redhatty value",
      "suse" => @array_values,
      :gentoo => "gentoo value",
      :default => "default value",
    }

    @platform_family_value = Chef::DSL::PlatformIntrospection::PlatformFamilyDependentValue.new(@platform_family_hash)
  end

  it "returns the default value when the platform family doesn't match" do
    expect(@platform_family_value.value_for_node(:platform_family => :os2)).to eq("default value")
  end

  it "returns a value for the platform family when it was set as a string but fetched as a symbol" do
    expect(@platform_family_value.value_for_node(:platform_family => :debian)).to eq("debian value")
  end

  it "returns a value for the platform family when it was set as a symbol but fetched as a string" do
    expect(@platform_family_value.value_for_node(:platform_family => "gentoo")).to eq("gentoo value")
  end

  it "returns an array value stored for a platform family" do
    expect(@platform_family_value.value_for_node(:platform_family => "suse")).to eq(@array_values)
  end

  it "returns a value for the platform family when it was set within an array hash key as a symbol" do
    expect(@platform_family_value.value_for_node(:platform_family => :rhel)).to eq("redhatty value")
  end

  it "returns a value for the platform family when it was set within an array hash key as a string" do
    expect(@platform_family_value.value_for_node(:platform_family => "fedora")).to eq("redhatty value")
  end

  it "returns nil if there is no default and no platforms match" do
    platform_specific_value = Chef::DSL::PlatformIntrospection::PlatformFamilyDependentValue.new({})
    expect(platform_specific_value.value_for_node(:platform_family => "foo")).to be_nil
  end

end
