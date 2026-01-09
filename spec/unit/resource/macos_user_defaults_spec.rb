#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::MacosUserDefaults, :macos_only do
  let(:test_value) { "fakest_key_value" }
  let(:test_key) { "fakest_key" }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) {
    Chef::Resource::MacosUserDefaults.new("foo", run_context).tap do |r|
      r.value test_value
      r.key test_key
    end
  }

  context "has a default value" do
    it ":macos_userdefaults for resource name" do
      expect(resource.resource_name).to eq(:macos_userdefaults)
    end

    it "NSGlobalDomain for the domain property" do
      expect(resource.domain).to eq("NSGlobalDomain")
    end

    it ":all for the host property" do
      expect(resource.host).to eq(:all)
    end

    it ":current for the user property" do
      expect(resource.user).to eq(:current)
    end

    it ":write for resource action" do
      expect(resource.action).to eq([:write])
    end
  end

  context ":write" do
    it "is a supported action" do
      expect { resource.action :write }.not_to raise_error
    end

    it "successfully updates the preference" do
      resource.run_action(:write)
      expect(resource.get_preference resource).eql? test_value
    end
  end

  context ":delete" do
    it "is a supported action" do
      expect { resource.action :delete }.not_to raise_error
    end

    it "successfully deletes the preference" do
      resource.run_action(:delete)
      expect(resource.get_preference resource).to be_nil
    end
  end
end
