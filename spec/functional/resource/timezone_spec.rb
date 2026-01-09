#
# Author:: Gary Bright (<digitalgaz@hotmail.com>)
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

describe Chef::Resource::Timezone, :windows_only do
  let(:timezone) { "GMT Standard Time" }

  def timezone_resource
    run_context = Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)

    Chef::Resource::Timezone.new(timezone, run_context)
  end

  describe "when a timezone is provided on windows" do
    it "should set a timezone" do
      timezone_resource.run_action(:set)
    end
  end

  describe "when a timezone is not provided on windows" do
    let(:timezone) { nil }
    it "raises an exception" do
      expect { timezone_resource.run_action(:set) }.to raise_error(Chef::Exceptions::ValidationFailed)
    end
  end
end
