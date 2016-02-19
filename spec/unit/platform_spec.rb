#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

describe Chef::Platform do

  context "while testing with fake data" do

    before :all do
      @original_platform_map = Chef::Platform.platforms
    end

    after :all do ||
      Chef::Platform.platforms = @original_platform_map
    end

    before(:each) do
      Chef::Platform.platforms = {
        :darwin => {
          ">= 10.11" => {
            :file => "new_darwinian",
          },
          "9.2.2" => {
            :file => "darwinian",
            :else => "thing",
          },
          :default => {
            :file => "old school",
            :snicker => "snack",
          },
        },
        :mars_volta => {
        },
        :default => {
          :file => Chef::Provider::File,
          :pax => "brittania",
          :cat => "nice",
        },
      }
      @events = Chef::EventDispatch::Dispatcher.new
    end

    it "should allow you to look up a platform by name and version, returning the provider map for it" do
      pmap = Chef::Platform.find("Darwin", "9.2.2")
      expect(pmap).to be_a_kind_of(Hash)
      expect(pmap[:file]).to eql("darwinian")
    end

    it "should allow you to look up a platform by name and version using \"greater than\" style operators" do
      pmap = Chef::Platform.find("Darwin", "11.1.0")
      expect(pmap).to be_a_kind_of(Hash)
      expect(pmap[:file]).to eql("new_darwinian")
    end

    it "should use the default providers for an os if the specific version does not exist" do
      pmap = Chef::Platform.find("Darwin", "1")
      expect(pmap).to be_a_kind_of(Hash)
      expect(pmap[:file]).to eql("old school")
    end

    it "should use the default providers if the os doesn't give me a default, but does exist" do
      pmap = Chef::Platform.find("mars_volta", "1")
      expect(pmap).to be_a_kind_of(Hash)
      expect(pmap[:file]).to eql(Chef::Provider::File)
    end

    it "should use the default provider if the os does not exist" do
      pmap = Chef::Platform.find("AIX", "1")
      expect(pmap).to be_a_kind_of(Hash)
      expect(pmap[:file]).to eql(Chef::Provider::File)
    end

    it "should merge the defaults for an os with the specific version" do
      pmap = Chef::Platform.find("Darwin", "9.2.2")
      expect(pmap[:file]).to eql("darwinian")
      expect(pmap[:snicker]).to eql("snack")
    end

    it "should merge the defaults for an os with the universal defaults" do
      pmap = Chef::Platform.find("Darwin", "9.2.2")
      expect(pmap[:file]).to eql("darwinian")
      expect(pmap[:pax]).to eql("brittania")
    end

    it "should allow you to look up a provider for a platform directly by symbol" do
      expect(Chef::Platform.find_provider("Darwin", "9.2.2", :file)).to eql("darwinian")
    end

    it "should raise an exception if a provider cannot be found for a resource type" do
      expect { Chef::Platform.find_provider("Darwin", "9.2.2", :coffee) }.to raise_error(Chef::Exceptions::ProviderNotFound)
    end

    it "should look up a provider for a resource with a Chef::Resource object" do
      kitty = Chef::Resource::Cat.new("loulou")
      expect(Chef::Platform.find_provider("Darwin", "9.2.2", kitty)).to eql("nice")
    end

    it "should look up a provider with a node and a Chef::Resource object" do
      kitty = Chef::Resource::Cat.new("loulou")
      node = Chef::Node.new
      node.name("Intel")
      node.automatic_attrs[:platform] = "mac_os_x"
      node.automatic_attrs[:platform_version] = "9.2.2"
      expect(Chef::Platform.find_provider_for_node(node, kitty)).to eql("nice")
    end

    it "should not throw an exception when the platform version has an unknown format" do
      expect(Chef::Platform.find_provider(:darwin, "bad-version", :file)).to eql("old school")
    end

    it "should prefer an explicit provider" do
      kitty = Chef::Resource::Cat.new("loulou")
      allow(kitty).to receive(:provider).and_return(Chef::Provider::File)
      node = Chef::Node.new
      node.name("Intel")
      node.automatic_attrs[:platform] = "mac_os_x"
      node.automatic_attrs[:platform_version] = "9.2.2"
      expect(Chef::Platform.find_provider_for_node(node, kitty)).to eql(Chef::Provider::File)
    end

    it "should look up a provider based on the resource name if nothing else matches" do
      kitty = Chef::Resource::Cat.new("loulou")
      class Chef::Provider::Cat < Chef::Provider; end
      Chef::Platform.platforms[:default].delete(:cat)
      node = Chef::Node.new
      node.name("Intel")
      node.automatic_attrs[:platform] = "mac_os_x"
      node.automatic_attrs[:platform_version] = "8.5"
      expect(Chef::Platform.find_provider_for_node(node, kitty)).to eql(Chef::Provider::Cat)
    end

    def setup_file_resource
      node = Chef::Node.new
      node.automatic_attrs[:platform] = "mac_os_x"
      node.automatic_attrs[:platform_version] = "9.2.2"
      run_context = Chef::RunContext.new(node, {}, @events)
      [ Chef::Resource::File.new("whateva", run_context), run_context ]
    end

    it "returns a provider object given a Chef::Resource object which has a valid run context and an action" do
      file, run_context = setup_file_resource
      provider = Chef::Platform.provider_for_resource(file, :foo)
      expect(provider).to be_an_instance_of(Chef::Provider::File)
      expect(provider.new_resource).to equal(file)
      expect(provider.run_context).to equal(run_context)
    end

    it "returns a provider object given a Chef::Resource object which has a valid run context without an action" do
      file, run_context = setup_file_resource
      provider = Chef::Platform.provider_for_resource(file)
      expect(provider).to be_an_instance_of(Chef::Provider::File)
      expect(provider.new_resource).to equal(file)
      expect(provider.run_context).to equal(run_context)
    end

    it "raises an error when trying to find the provider for a resource with no run context" do
      file = Chef::Resource::File.new("whateva")
      expect { Chef::Platform.provider_for_resource(file) }.to raise_error(ArgumentError)
    end

    it "does not support finding a provider by resource and node -- a run context is required" do
      expect { Chef::Platform.provider_for_node("node", "resource") }.to raise_error(NotImplementedError)
    end

    it "should update the provider map with map" do
      Chef::Platform.set(
           :platform => :darwin,
           :version => "9.2.2",
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:darwin]["9.2.2"][:file]).to eql("masterful")
      Chef::Platform.set(
           :platform => :darwin,
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:darwin][:default][:file]).to eql("masterful")
      Chef::Platform.set(
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:default][:file]).to eql("masterful")

      Chef::Platform.set(
           :platform => :hero,
           :version => "9.2.2",
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:hero]["9.2.2"][:file]).to eql("masterful")

      Chef::Platform.set(
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:default][:file]).to eql("masterful")

      Chef::Platform.platforms = {}

      Chef::Platform.set(
           :resource => :file,
           :provider => "masterful"
      )
      expect(Chef::Platform.platforms[:default][:file]).to eql("masterful")

      Chef::Platform.platforms = { :neurosis => {} }
      Chef::Platform.set(:platform => :neurosis, :resource => :package, :provider => "masterful")
      expect(Chef::Platform.platforms[:neurosis][:default][:package]).to eql("masterful")

    end

    it "does not overwrite the platform map when using :default platform" do
      Chef::Platform.set(
        :resource => :file,
        :platform => :default,
        :provider => "new school"
      )
      expect(Chef::Platform.platforms[:default][:file]).to eql("new school")
      expect(Chef::Platform.platforms[:default][:cat]).to eql("nice")
    end

  end

end
