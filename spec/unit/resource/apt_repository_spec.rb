#
# Author:: Thom May (<thom@chef.io>)
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

describe Chef::Resource::AptRepository do
  let(:node) { Chef::Node.new }
  let(:run_context) do
    node.automatic[:lsb][:codename] = "superduper"
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end
  let(:resource) { Chef::Resource::AptRepository.new("fakey_fakerton", run_context) }

  it "keyserver defaults to keyserver.ubuntu.com" do
    expect(resource.keyserver).to eql("keyserver.ubuntu.com")
  end

  it "the repo_name property is the name_property" do
    expect(resource.repo_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :add" do
    expect(resource.action).to eql([:add])
  end

  it "supports :add, :remove actions" do
    expect { resource.action :add }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "distribution defaults to the distro codename" do
    expect(resource.distribution).to eql("superduper")
  end

  it "allows setting key to an Array of keys and does not coerce it" do
    resource.key = %w{key1 key2}
    expect(resource.key).to eql(%w{key1 key2})
  end

  it "allows setting key to nil and does not coerce it" do
    resource.key = nil
    expect(resource.key).to be_nil
  end

  it "allows setting key to false and does not coerce it" do
    resource.key = false
    expect(resource.key).to be false
  end

  it "allows setting key to a String and coerces it to an Array" do
    resource.key = "key1"
    expect(resource.key).to eql(["key1"])
  end

  it "allows setting options to a String and coerces it to an Array" do
    resource.options = "by-hash=no"
    expect(resource.options).to eql(["by-hash=no"])
  end

  it "fails if the user provides a repo_name with a forward slash" do
    expect { resource.repo_name "foo/bar" }.to raise_error(ArgumentError)
  end
end
