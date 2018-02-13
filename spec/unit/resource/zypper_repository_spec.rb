#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) 2017 Chef Software, Inc.
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

describe Chef::Resource::ZypperRepository do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::ZypperRepository.new("repo-source", run_context) }

  context "on linux", :linux_only do
    it "should create a new Chef::Resource::ZypperRepository" do
      expect(resource).to be_a_kind_of(Chef::Resource)
      expect(resource).to be_a_kind_of(Chef::Resource::ZypperRepository)
    end

    it "should have a name of repo-source" do
      expect(resource.name).to eql("repo-source")
    end

    it "should have a default action of create" do
      expect(resource.action).to eql([:create])
    end

    it "supports all valid actions" do
      expect { resource.action :add }.not_to raise_error
      expect { resource.action :remove }.not_to raise_error
      expect { resource.action :create }.not_to raise_error
      expect { resource.action :refresh }.not_to raise_error
      expect { resource.action :delete }.to raise_error(ArgumentError)
    end

    it "resolves to a Noop class when on non-linux OS" do
      node.automatic[:os] = "windows"
      node.automatic[:platform_family] = "windows"
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end

    it "resolves to a Noop class when on non-suse linux" do
      node.automatic[:os] = "linux"
      node.automatic[:platform_family] = "debian"
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end

    it "resolves to a ZypperRepository class when on a suse platform_family" do
      node.automatic[:os] = "linux"
      node.automatic[:platform_family] = "suse"
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::ZypperRepository)
    end
  end
end
