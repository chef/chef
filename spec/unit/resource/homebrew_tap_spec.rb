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

describe Chef::Resource::HomebrewTap do

  let(:resource) { Chef::Resource::HomebrewTap.new("user/mytap") }

  it "has a resource name of :homebrew_tap" do
    expect(resource.resource_name).to eql(:homebrew_tap)
  end

  it "the tap_name property is the name_property" do
    expect(resource.tap_name).to eql("user/mytap")
  end

  it "sets the default action as :tap" do
    expect(resource.action).to eql([:tap])
  end

  it "supports :tap, :untap actions" do
    expect { resource.action :tap }.not_to raise_error
    expect { resource.action :untap }.not_to raise_error
  end

  it "fails if tap_name isn't in the USER/TAP format" do
    expect { resource.tap_name "mytap" }.to raise_error(ArgumentError)
  end

  describe "action :tap" do
    let(:node) { Chef::Node.new }
    let(:events) { Chef::EventDispatch::Dispatcher.new }
    let(:run_context) { Chef::RunContext.new(node, {}, events) }
    let(:resource) { Chef::Resource::HomebrewTap.new("user/mytap", run_context) }
    let(:commands_run) { [] }
    let(:execute_resources) { [] }

    before do
      # Stub homebrew_bin_path (used both by `tapped?` and inside the
      # action's `execute` commands) so this test doesn't depend on a real
      # "brew" executable being present on the PATH. `brew` is only
      # installed on the macOS CI runners; on Linux/Windows,
      # homebrew_bin_path raises Chef::Exceptions::CannotDetermineHomebrewPath.
      # This is stubbed on the action_class (provider) since that's where
      # `tapped?` and the action block actually execute, not on the
      # resource itself.
      allow_any_instance_of(Chef::Resource::HomebrewTap.action_class).to receive(:homebrew_bin_path).and_return("/usr/local/bin/brew")
      shellout = double("Mixlib::ShellOut").as_null_object
      allow(Mixlib::ShellOut).to receive(:new) do |command, *_args|
        commands_run << command
        shellout
      end
      allow(Chef::Resource::Execute).to receive(:new).and_wrap_original do |method, *args, &block|
        execute_resources << (r = method.call(*args, &block))
        r
      end
    end

    it "trusts the tap before tapping it, ignoring trust failures" do
      resource.run_action(:tap)

      expect(commands_run.first).to include("brew trust user/mytap")
      expect(commands_run.last).to include("brew tap user/mytap")

      trust_step = execute_resources.find { |r| r.name == "trust user/mytap" }
      expect(trust_step.ignore_failure).to be true

      tap_step = execute_resources.find { |r| r.name == "tap user/mytap" }
      expect(tap_step.ignore_failure).to be_falsey
    end
  end
end
