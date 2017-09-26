#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: 2016-2017, Chef Software, Inc.
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

describe Chef::Resource::AptRepository do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::AptRepository.new("multiverse", run_context) }

  it "creates a new Chef::Resource::AptRepository" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::AptRepository)
  end

  it "uses keyserver.ubuntu.com as the keyserver" do
    expect(resource.keyserver).to eql("keyserver.ubuntu.com")
  end

  it "default distribution is nillable" do
    expect(resource.distribution(nil)).to eql(nil)
    expect(resource.distribution).to eql(nil)
  end

  it "resolves to a Noop class when on non-linux OS" do
    node.automatic[:os] = "windows"
    node.automatic[:platform_family] = "windows"
    expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
  end

  it "resolves to a Noop class when on non-debian linux" do
    node.automatic[:os] = "linux"
    node.automatic[:platform_family] = "gentoo"
    expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
  end

  it "resolves to a AptUpdate class when on a debian platform_family" do
    node.automatic[:os] = "linux"
    node.automatic[:platform_family] = "debian"
    expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::AptRepository)
  end
end
