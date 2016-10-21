#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

  it "should create a new Chef::Resource::AptRepository" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::AptRepository)
  end

  it "the default keyserver should be keyserver.ubuntu.com" do
    expect(resource.keyserver).to eql("keyserver.ubuntu.com")
  end

  it "the default distribution should be nillable" do
    expect(resource.distribution(nil)).to eql(nil)
    expect(resource.distribution).to eql(nil)
  end

  it "should resolve to a Noop class when apt-get is not found" do
    expect(Chef::Provider::AptRepository).to receive(:which).with("apt-get").and_return(false)
    expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
  end

  it "should resolve to a AptRepository class when apt-get is found" do
    expect(Chef::Provider::AptRepository).to receive(:which).with("apt-get").and_return(true)
    expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::AptRepository)
  end
end
