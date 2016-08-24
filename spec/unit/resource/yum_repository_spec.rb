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

describe Chef::Resource::YumRepository do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::YumRepository.new("multiverse", run_context) }

  context "on linux", :linux_only do
    it "should create a new Chef::Resource::YumRepository" do
      expect(resource).to be_a_kind_of(Chef::Resource)
      expect(resource).to be_a_kind_of(Chef::Resource::YumRepository)
    end

    it "should resolve to a Noop class when yum is not found" do
      expect(Chef::Provider::YumRepository).to receive(:which).with("yum").and_return(false)
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end

    it "should resolve to a YumRepository class when yum is found" do
      expect(Chef::Provider::YumRepository).to receive(:which).with("yum").and_return(true)
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::YumRepository)
    end
  end

  context "on windows", :windows_only do
    it "should resolve to a NoOp provider" do
      expect(resource.provider_for_action(:add)).to be_a(Chef::Provider::Noop)
    end
  end
end
