#
# Author:: Tim Smith (<tsmith@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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
  let(:resource) { Chef::Resource::ZypperRepository.new("fakey_fakerton", run_context) }

  it "has a resource_name of :zypper_repository" do
    expect(resource.resource_name).to eq(:zypper_repository)
  end

  it "the repo_name property is the name_property" do
    expect(resource.repo_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "supports :add, :create, :refresh, :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :refresh }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "fails if the user provides a repo_name with a forward slash" do
    expect { resource.repo_name "foo/bar" }.to raise_error(ArgumentError)
  end

  it "type property defaults to 'NONE'" do
    expect(resource.type).to eql("NONE")
  end

  it "enabled property defaults to true" do
    expect(resource.enabled).to eql(true)
  end

  it "autorefresh property defaults to true" do
    expect(resource.autorefresh).to eql(true)
  end

  it "gpgcheck property defaults to true" do
    expect(resource.gpgcheck).to eql(true)
  end

  it "keeppackages property defaults to false" do
    expect(resource.keeppackages).to eql(false)
  end

  it "priority property defaults to 99" do
    expect(resource.priority).to eql(99)
  end

  it "mode property defaults to '0644'" do
    expect(resource.mode).to eql("0644")
  end

  it "refresh_cache property defaults to true" do
    expect(resource.refresh_cache).to eql(true)
  end

  it "gpgautoimportkeys property defaults to true" do
    expect(resource.gpgautoimportkeys).to eql(true)
  end

  it "accepts the legacy 'key' property" do
    resource.key "foo"
    expect(resource.gpgkey).to eql(["foo"])
  end

  it "accepts the legacy 'uri' property" do
    resource.uri "foo"
    expect(resource.baseurl).to eql("foo")
  end

  context "on linux", :linux_only do
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
