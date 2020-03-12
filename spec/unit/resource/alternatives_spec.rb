#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: 2020, Chef Software Inc.
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

describe Chef::Resource::Alternatives do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::Alternatives.new("fakey_fakerton", run_context) }
  let(:provider) { resource.provider_for_action(:install) }

  it "the link_name property is the name_property" do
    expect(resource.link_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "coerces priority value to an Integer" do
    resource.priority("1")
    expect(resource.priority).to eql(1)
  end

  it "builds a default value for link based on link_name value" do
    expect(resource.link).to eql("/usr/bin/fakey_fakerton")
  end

  it "supports :install, :auto, :refresh, and :remove actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :auto }.not_to raise_error
    expect { resource.action :refresh }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  describe "#alternatives_cmd" do
    it "returns alternatives on fedora" do
      node.automatic_attrs[:platform_family] = "fedora"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns alternatives on amazon" do
      node.automatic_attrs[:platform_family] = "amazon"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns alternatives on redhat" do
      node.automatic_attrs[:platform_family] = "rhel"
      expect(provider.alternatives_cmd).to eql("alternatives")
    end

    it "returns update-alternatives on debian" do
      node.automatic_attrs[:platform_family] = "debian"
      expect(provider.alternatives_cmd).to eql("update-alternatives")
    end
  end
end
