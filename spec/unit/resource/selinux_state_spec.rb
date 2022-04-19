#
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

describe Chef::Resource::SelinuxState do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::SelinuxState.new("5678", run_context) }
  let(:provider) { resource.provider_for_action(:enforcing) }

  it "sets the default action as :enforcing" do
    expect(resource.action).to eql([:enforcing])
  end

  it "sets default value for policy property for 'rhel', 'fedora', 'amazon' platforms" do
    node.automatic_attrs[:platform_family] = "rhel"
    expect(resource.policy).to eql("targeted")
  end

  it "supports :enforcing, :permissive, :disabled actions" do
    expect { resource.action :enforcing }.not_to raise_error
    expect { resource.action :permissive }.not_to raise_error
    expect { resource.action :disabled }.not_to raise_error
  end

  it "sets default value for policy property for debian platforms" do
    node.automatic_attrs[:platform_family] = "debian"
    expect(resource.policy).to eql("default")
  end
end