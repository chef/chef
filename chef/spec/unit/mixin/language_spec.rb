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
    @platform_hash["debian"] = {["5", "6"] => "debian-5/6", "default" => "debian"} 
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

  describe "when platform versions is an array" do
    it "returns a version-specific value based on the current platform" do
      @node[:platform] = "debian"
      @node[:platform_version] = "6"
      @language.value_for_platform(@platform_hash).should == "debian-5/6"
    end

    it "returns a value based on the current platform if version not found" do
      @node[:platform] = "debian"
      @node[:platform_version] = "0.0.0"
      @language.value_for_platform(@platform_hash).should == "debian"
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
      @node[:platform] = "debian"
      @node[:platform_version] = '9000'
      @language.value_for_platform(@platform_hash).should == [ :restart, :reload, :status ]
    end

    it "returns the correct platform+version specific value " do
      @node[:platform] = "debian"
      @node[:platform_version] = '4.0'
      @language.value_for_platform(@platform_hash).should == [:restart, :reload]
    end

  end

  describe "when loading data bags and items" do
    it "lists the items in a data bag" do
      Chef::DataBag.should_receive(:load).with("bag_name").and_return("item_1" => "http://url_for/item_1", "item_2" => "http://url_for/item_2")
      @language.data_bag("bag_name").should == %w[item_1 item_2]
    end

    it "validates the name of the data bag you're trying to load" do
      lambda {@language.data_bag("!# %^&& ")}.should raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "fetches a data bag item" do
      @item = Chef::DataBagItem.new
      @item.data_bag("bag_name")
      @item.raw_data = {"id" => "item_name", "FUU" => "FUU"}
      Chef::DataBagItem.should_receive(:load).with("bag_name", "item_name").and_return(@item)
      @language.data_bag_item("bag_name", "item_name").should == @item
    end

    it "validates the name of the data bag you're trying to load an item from" do
      lambda {@language.data_bag_item(" %%^& ", "item_name")}.should raise_error(Chef::Exceptions::InvalidDataBagName)
    end

    it "validates the id of the data bag item you're trying to load" do
      lambda {@language.data_bag_item("bag_name", " 987 (*&()")}.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

    it "validates that the id of the data bag item is not nil" do
      lambda {@language.data_bag_item("bag_name", nil)}.should raise_error(Chef::Exceptions::InvalidDataBagItemID)
    end

  end

end

describe Chef::Mixin::Language::PlatformDependentValue do
  before do
    platform_hash = {
      :openbsd => {:default => 'free, functional, secure'},
      [:redhat, :centos, :fedora, :scientific] => {:default => '"stable"'},
      :ubuntu => {'10.04' => 'using upstart more', :default => 'using init more'},
      :default => 'bork da bork'
    }
    @platform_specific_value = Chef::Mixin::Language::PlatformDependentValue.new(platform_hash)
  end

  it "returns the default value when the platform doesn't match" do
    @platform_specific_value.value_for_node(:platform => :dos).should == 'bork da bork'
  end

  it "returns a value for a platform set as a group" do
    @platform_specific_value.value_for_node(:platform => :centos).should == '"stable"'
  end

  it "returns a value for the platform when it was set as a symbol but fetched as a string" do
    @platform_specific_value.value_for_node(:platform => "centos").should == '"stable"'
  end

  it "returns a value for a specific platform version" do
    node = {:platform => 'ubuntu', :platform_version => '10.04'}
    @platform_specific_value.value_for_node(node).should == 'using upstart more'
  end

  it "returns a platform-default value if the platform version doesn't match an explicit one" do
    node = {:platform => 'ubuntu', :platform_version => '9.10' }
    @platform_specific_value.value_for_node(node).should == 'using init more'
  end

  it "returns nil if there is no default and no platforms match" do
    # this matches the behavior in the original implementation.
    # whether or not it's correct is another matter.
    platform_specific_value = Chef::Mixin::Language::PlatformDependentValue.new({})
    platform_specific_value.value_for_node(:platform => 'foo').should be_nil
  end

  it "raises an argument error if the platform hash is not correctly structured" do
    bad_hash = {:ubuntu => :foo} # should be :ubuntu => {:default => 'foo'}
    lambda {Chef::Mixin::Language::PlatformDependentValue.new(bad_hash)}.should raise_error(ArgumentError)
  end

end
