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

describe Chef::Resource::SelinuxPort do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxPort.new("5678", run_context) }
  let(:provider) { resource.provider_for_action(:manage) }

  it "sets port property as name_property" do
    expect(resource.port).to eql("5678")
  end

  it "sets the default action as :manage" do
    expect(resource.action).to eql([:manage])
  end

  it "supports :manage, :addormodify, :add, :modify, :delete actions" do
    expect { resource.action :manage }.not_to raise_error
    expect { resource.action :addormodify }.not_to raise_error
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :modify }.not_to raise_error
    expect { resource.action :delete }.not_to raise_error
  end
end
