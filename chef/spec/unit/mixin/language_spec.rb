#
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "spec_helper"))
require 'chef/mixin/language'

class LanguageTester
  include Chef::Mixin::Language
end

describe Chef::Mixin::Language do
  before(:each) do
    @language = LanguageTester.new
    @node = Hash.new
    @language.stub!(:node).and_return(@node)
    @platform_hash = {}
    %w{openbsd freebsd}.each do |x|
      @platform_hash[x] = {
        "default" => x,
        "1.2.3" => "#{x}-1.2.3"
      }
    end
    @platform_hash["default"] = "default"
  end

  it "returns a default value when there is no known platform" do
    @node = Hash.new
    @language.value_for_platform(@platform_hash).should == "default"
  end

  it "returns a default value when the current platform doesn't match" do
        @node[:platform] = "not-a-known-platform"
    @language.value_for_platform(@platform_hash).should == "default"
  end

  it "returns a value based on the current platform" do
    @node[:platform] = "openbsd"
    @language.value_for_platform(@platform_hash).should == "openbsd"
  end

  it "returns a version-specific value based on the current platform" do
    @node[:platform] = "openbsd"
    @node[:platform_version] = "1.2.3"
    @language.value_for_platform(@platform_hash).should == "openbsd-1.2.3"
  end

  it "returns a value based on the current platform if version not found" do
    @node[:platform] = "openbsd"
    @node[:platform_version] = "0.0.0"
    @language.value_for_platform(@platform_hash).should == "openbsd"
  end

end

