#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Resource::PlatformMap do

  before :all do
    @original_platform_map = Chef::Resource::PlatformMap.platforms
  end

  after :all do ||
    Chef::Resource::PlatformMap.platforms = @original_platform_map
  end

  before(:each) do
    Chef::Resource::PlatformMap.platforms = {
      :windows => {
        "6.1" => {
          :file => "softiefile",
          :else => "thing"
        },
        :default => {
          :file => Chef::Resource::File,
          :ping => "pong",
          :cat => "nice"
        }
      },
      :pop_tron => {
      },
      :default => {
        :soundwave => "laszerbeak",
        :directory => Chef::Resource::Directory,
      }
    }
  end

  describe 'search the platform map' do
    it "allows lookup for a platform by name and version, returning the resource map for it" do
      pmap = Chef::Resource::PlatformMap.find("Windows", "6.1")
      pmap.should be_a_kind_of(Hash)
      pmap[:file].should eql("softiefile")
    end

    it "returns the default resources for an os if the specific version does not exist" do
      pmap = Chef::Resource::PlatformMap.find("windows", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:file].should eql(Chef::Resource::File)
    end

    it "returns the default resources if the os doesn't give me a default, but does exist" do
      pmap = Chef::Resource::PlatformMap.find("pop_tron", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:directory].should eql(Chef::Resource::Directory)
    end

    it "returns the default resource if the os does not exist" do
      pmap = Chef::Resource::PlatformMap.find("BeOS", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:soundwave].should eql("laszerbeak")
    end

    it "merges the defaults for an os with the specific version" do
      pmap = Chef::Resource::PlatformMap.find("Windows", "6.1")
      pmap[:file].should eql("softiefile")
      pmap[:ping].should eql("pong")
    end
  end

  describe 'locate a resource' do
    it "returns a resource for a platform directly by short name" do
      Chef::Resource::PlatformMap.find_resource("windows", "6.1", :file).should eql("softiefile")
    end

    it "match short_name to a resource class if a platform and version dont' exist" do
      Chef::Resource::PlatformMap.find_resource(nil, nil, :remote_file).should eql(Chef::Resource::RemoteFile)
    end

    it "raises an exception if a resource cannot be found for a short name" do
      lambda { Chef::Resource::PlatformMap.find_resource("windows", "6.1", :coffee)}.should raise_error(NameError)
    end

    it "returns a resource with a Chef::Resource object" do
      kitty = Chef::Resource::Cat.new("loulou")
      Chef::Resource::PlatformMap.find_resource("windows", "6.1", kitty).should eql("nice")
    end
  end

  describe "lookup by node" do

    before(:each) do
      @node = Chef::Node.new
      @node.name("Intel")
      @node.platform("windows")
      @node.platform_version("6.1")
    end

    it "returns a resource with a node and a short_name" do
      Chef::Resource::PlatformMap.find_resource_for_node(@node, :cat).should eql("nice")
    end

    it "returns a resource based on short_name if nothing else matches" do
      Chef::Resource::Cat.new("loulou")
      Chef::Resource::PlatformMap.platforms[:windows][:default].delete(:cat)
      Chef::Resource::PlatformMap.find_resource_for_node(@node, :cat).should eql(Chef::Resource::Cat)
    end

  end

  it "should update the provider map with map" do
    Chef::Resource::PlatformMap.set(
     :platform => :darwin,
     :version => "9.2.2",
     :short_name => :file,
     :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:darwin]["9.2.2"][:file].should eql("masterful")

    Chef::Resource::PlatformMap.set(
     :platform => :darwin,
     :short_name => :file,
     :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:darwin][:default][:file].should eql("masterful")

    Chef::Resource::PlatformMap.set(
     :short_name => :file,
     :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:default][:file].should eql("masterful")

    Chef::Resource::PlatformMap.set(
     :platform => :hero,
     :version => "9.2.2",
     :short_name => :file,
     :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:hero]["9.2.2"][:file].should eql("masterful")

    Chef::Resource::PlatformMap.set(
      :short_name => :file,
      :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:default][:file].should eql("masterful")

    Chef::Resource::PlatformMap.platforms = {}

    Chef::Resource::PlatformMap.set(
     :short_name => :file,
     :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:default][:file].should eql("masterful")

    Chef::Resource::PlatformMap.platforms = { :neurosis => {} }
    Chef::Resource::PlatformMap.set(
      :platform => :neurosis,
      :short_name => :package,
      :resource => "masterful"
    )
    Chef::Resource::PlatformMap.platforms[:neurosis][:default][:package].should eql("masterful")
  end

end
