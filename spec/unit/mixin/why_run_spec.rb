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

describe Chef::Mixin::WhyRun::ResourceRequirements do
  class TestResource < Chef::Resource
    action_class do
      def define_resource_requirements
        requirements.assert(:boom) do |a|
          a.assertion { raise "boom1" }
          a.failure_message("#{raise "boom2"}")
          a.whyrun("#{raise "boom3"}")
        end
      end
    end

    action :boom do
      # nothing
    end

    action :noboom do
      # nothing
    end
  end

  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { TestResource.new("name", run_context) }

  it "raises an exception for an action where the assertions raise exceptions" do
    expect { resource.run_action(:boom) }.to raise_error(StandardError, /boom2/)
  end

  it "does not raise an exception for an action which has no assertions" do
    resource.run_action(:noboom)
  end
end
