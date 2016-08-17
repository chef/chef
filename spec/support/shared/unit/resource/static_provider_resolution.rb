#
# Author:: Lamont Granquist (<lamont@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

#
# This is for typical "static" provider resolution which maps resources onto
# providers based only on the node data.  Its not really 'static' because it
# all goes through the Chef::ProviderResolver, but the effective result is
# a static mapping for the node (unlike the service resource which is
# complicated).
#
def static_provider_resolution(opts = {})
  action           = opts[:action]
  provider_class   = opts[:provider]
  resource_class   = opts[:resource]
  name             = opts[:name]
  os               = opts[:os]
  platform_family  = opts[:platform_family]
  platform_version = opts[:platform_version]

  describe resource_class, "static provider initialization" do
    let(:node) do
      node = Chef::Node.new
      node.automatic_attrs[:os] = os
      node.automatic_attrs[:platform_family] = platform_family
      node.automatic_attrs[:platform_version] = platform_version
      node
    end
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:resource) { resource_class.new("foo", run_context) }

    it "should return a #{resource_class}" do
      expect(resource).to be_a_kind_of(resource_class)
    end

    it "should set the resource_name to #{name}" do
      expect(resource.resource_name).to eql(name)
    end

    it "should leave the provider nil" do
      expect(resource.provider).to eql(nil)
    end

    it "should resolve to a #{provider_class}" do
      expect(resource.provider_for_action(action)).to be_a(provider_class)
    end
  end
end
