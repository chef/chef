#
# Author:: Serdar Sutay (<serdar@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software Inc.
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

describe Chef::Resource::WhyrunSafeRubyBlock do
  let(:node) { Chef::Node.new }

  let(:run_context) do
    events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, events)
  end

  before do
    $evil_global_evil_laugh = :wahwah
    Chef::Config[:why_run] = true
  end

  after do
    Chef::Config[:why_run] = false
  end

  describe "when testing the resource" do
    let(:new_resource) do
      r = Chef::Resource::WhyrunSafeRubyBlock.new("reload all", run_context)
      r.block { $evil_global_evil_laugh = :mwahahaha }
      r
    end

    it "updates the evil laugh, even in why-run mode" do
      Array(new_resource.action).each { |action| new_resource.run_action(action) }
      expect($evil_global_evil_laugh).to eq(:mwahahaha)
      expect(new_resource).to be_updated
    end
  end
end
