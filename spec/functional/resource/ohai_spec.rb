#
# Author:: Serdar Sutay (<serdar@chef.io>)
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

describe Chef::Resource::Ohai do
  let(:node) { Chef::Node.new }

  let(:run_context) do
    node.default[:platform] = ohai[:platform]
    node.default[:platform_version] = ohai[:platform_version]
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  shared_examples_for "reloaded :uptime" do
    it "should reload :uptime" do
      expect(node[:uptime_seconds]).to be nil
      ohai_resource.run_action(:reload)
      expect(Integer(node[:uptime_seconds])).to be_an(Integer)
    end
  end

  describe "when reloading all plugins" do
    let(:ohai_resource) { Chef::Resource::Ohai.new("reload all", run_context) }

    it_behaves_like "reloaded :uptime"
  end

  describe "when reloading only uptime" do
    let(:ohai_resource) do
      r = Chef::Resource::Ohai.new("reload all", run_context)
      r.plugin("uptime")
      r
    end

    it_behaves_like "reloaded :uptime"
  end
end
