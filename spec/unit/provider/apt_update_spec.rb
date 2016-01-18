#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

describe Chef::Provider::AptUpdate do
  let(:new_resource) { Chef::Resource::AptUpdate.new("update") }

  let(:provider) do
    node = Chef::Node.new
    events = Chef::EventDispatch::Dispatcher.new
    run_context = Chef::RunContext.new(node, {}, events)
    Chef::Provider::AptUpdate.new(new_resource, run_context)
  end

  it "responds to load_current_resource" do
    expect(provider).to respond_to(:load_current_resource)
  end

  describe "#action_update" do
    it "should update the apt cache" do
      provider.load_current_resource
      expect(provider).to receive(:shell_out!).with("apt-get -q update").and_return(double)
      provider.run_action(:update)
      expect(new_resource).to be_updated_by_last_action
    end
  end
end
