#
# Author:: Adam Edwards (<adamed@chef.io>)
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
describe Chef::Provider::PowershellScript, "action_run" do
  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(Chef::Node.new, {}, events) }

  let(:new_resource) do
    Chef::Resource::PowershellScript.new("run some powershell code", run_context)
  end

  let(:provider) do
    Chef::Provider::PowershellScript.new(new_resource, run_context)
  end

  context "when setting interpreter flags" do
    before(:each) do
      allow(provider).to receive(:basepath).and_return("C:\\Windows\\system32")
    end

    it "sets the -File flag as the last flag" do
      flags = provider.command.split(" ").keep_if { |flag| flag =~ /^-/ }
      expect(flags.pop).to eq("-File")
    end
  end
end
