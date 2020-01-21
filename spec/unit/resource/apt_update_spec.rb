#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: 2016-2019, Chef Software Inc.
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

describe Chef::Resource::AptUpdate do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) { Chef::Resource::AptUpdate.new("update", run_context) }

  it "sets the default action as :periodic" do
    expect(resource.action).to eql([:periodic])
  end

  it "supports :periodic, :update actions" do
    expect { resource.action :periodic }.not_to raise_error
    expect { resource.action :update }.not_to raise_error
  end

  it "default frequency is set to be 1 day" do
    expect(resource.frequency).to eql(86_400)
  end

  it "frequency accepts integers" do
    resource.frequency(400)
    expect(resource.frequency).to eql(400)
  end
end
