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

describe Chef::ActionCollection do
  describe "#resource_completed" do
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(Chef::Node.new, {}, events) }
    let(:action_collection) { described_class.new(events, run_context) }

    it "preserves sensitive DSC resources without exposing their properties" do
      resource = Chef::Resource::DscResource.new("sensitive_dsc", run_context)
      resource.property(:Secret, "secret value")
      resource.sensitive(true)
      action_collection.pending_updates << described_class::ActionRecord.new(resource, :run, 0)

      action_collection.resource_completed(resource)

      completed_resource = action_collection.last.new_resource
      expect(completed_resource).to be_a(Chef::Resource::DscResource)
      expect(completed_resource.name).to eq("sensitive_dsc")
      expect(completed_resource.properties).to be_empty
    end
  end
end
