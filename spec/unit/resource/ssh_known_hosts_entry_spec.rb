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

describe Chef::Resource::SshKnownHostsEntry do
  let(:node) { Chef::Node.new }
  let(:run_context) do
    node.automatic[:root_group] = "superduper"
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end
  let(:resource) { Chef::Resource::SshKnownHostsEntry.new("example.com", run_context) }

  it "sets resource name as :ssh_known_hosts_entry" do
    expect(resource.resource_name).to eql(:ssh_known_hosts_entry)
  end

  it "sets group property to node['root_group'] by default" do
    expect(resource.group).to eql("superduper")
  end

  it "sets the default action as :create" do
    expect(resource.action).to eql([:create])
  end

  it "sets the host property as its name property" do
    expect(resource.host).to eql("example.com")
  end

  it "supports :create and :flush actions" do
    expect { resource.action :create }.not_to raise_error
    expect { resource.action :flush }.not_to raise_error
    expect { resource.action :delete }.to raise_error(ArgumentError)
  end
end
