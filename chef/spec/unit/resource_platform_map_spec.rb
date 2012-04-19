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

require 'spec_helper'

describe Chef::Resource::PlatformMap do

  before(:each) do
    @platform_map = Chef::Resource::PlatformMap.new({
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
        :soundwave => "lazerbeak",
        :directory => Chef::Resource::Directory,
      }
    })
  end

  describe 'filtering the map' do
    it "returns resources for platform and version" do
      pmap = @platform_map.filter("Windows", "6.1")
      pmap.should be_a_kind_of(Hash)
      pmap[:file].should eql("softiefile")
    end

    it "returns platform default resources if version does not exist" do
      pmap = @platform_map.filter("windows", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:file].should eql(Chef::Resource::File)
    end

    it "returns global default resources if none exist for plaform" do
      pmap = @platform_map.filter("pop_tron", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:directory].should eql(Chef::Resource::Directory)
    end

    it "returns global default resources if platform does not exist" do
      pmap = @platform_map.filter("BeOS", "1")
      pmap.should be_a_kind_of(Hash)
      pmap[:soundwave].should eql("lazerbeak")
    end

    it "returns a merged map of platform version and plaform default resources" do
      pmap = @platform_map.filter("Windows", "6.1")
      pmap[:file].should eql("softiefile")
      pmap[:ping].should eql("pong")
    end

    it "returns a merged map of platform specific version and global defaults" do
      pmap = @platform_map.filter("Windows", "6.1")
      pmap[:file].should eql("softiefile")
      pmap[:soundwave].should eql("lazerbeak")
    end
  end

  describe 'finding a resource' do
    it "returns a resource for a platform directly by short name" do
      @platform_map.get(:file, "windows", "6.1").should eql("softiefile")
    end

    it "returns a default resource if platform and version don't exist" do
      @platform_map.get(:remote_file).should eql(Chef::Resource::RemoteFile)
    end

    it "raises an exception if a resource cannot be found" do
      lambda { @platform_map.get(:coffee, "windows", "6.1")}.should raise_error(NameError)
    end

    it "returns a resource with a Chef::Resource object" do
      kitty = Chef::Resource::Cat.new("loulou")
      @platform_map.get(kitty, "windows", "6.1").should eql("nice")
    end
  end

  describe 'building the map' do
    it "allows passing of a resource map at creation time" do
      @new_map = Chef::Resource::PlatformMap.new({:the_dude => {:default => 'abides'}})
      @new_map.map[:the_dude][:default].should eql("abides")
    end

    it "defaults to a resource map with :default key" do
      @new_map = Chef::Resource::PlatformMap.new
      @new_map.map.has_key?(:default)
    end

    it "updates the resource map with a map" do
      @platform_map.set(
       :platform => :darwin,
       :version => "9.2.2",
       :short_name => :file,
       :resource => "masterful"
      )
      @platform_map.map[:darwin]["9.2.2"][:file].should eql("masterful")

      @platform_map.set(
       :platform => :darwin,
       :short_name => :file,
       :resource => "masterful"
      )
      @platform_map.map[:darwin][:default][:file].should eql("masterful")

      @platform_map.set(
       :short_name => :file,
       :resource => "masterful"
      )
      @platform_map.map[:default][:file].should eql("masterful")

      @platform_map.set(
       :platform => :hero,
       :version => "9.2.2",
       :short_name => :file,
       :resource => "masterful"
      )
      @platform_map.map[:hero]["9.2.2"][:file].should eql("masterful")

      @platform_map.set(
        :short_name => :file,
        :resource => "masterful"
      )
      @platform_map.map[:default][:file].should eql("masterful")

      @platform_map.set(
       :short_name => :file,
       :resource => "masterful"
      )
      @platform_map.map[:default][:file].should eql("masterful")

      @platform_map.set(
        :platform => :neurosis,
        :short_name => :package,
        :resource => "masterful"
      )
      @platform_map.map[:neurosis][:default][:package].should eql("masterful")
    end
  end

end
