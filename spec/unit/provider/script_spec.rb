#
# Author:: Adam Jacob (adam@chef.io)
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

describe Chef::Provider::Script, "action_run" do
  let(:node) { Chef::Node.new }

  let(:events) { Chef::EventDispatch::Dispatcher.new }

  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) do
    new_resource = Chef::Resource::Script.new("run some perl code")
    new_resource.code "$| = 1; print 'i like beans'"
    new_resource.interpreter "perl"
    new_resource
  end

  let(:provider) { Chef::Provider::Script.new(new_resource, run_context) }

  describe "#command" do
    it "is only the intepreter in quotes by default" do
      expect(provider.command.strip).to eq(%q{"perl"})
    end

    it "is the interpreter in quotes with the flags when flags are used" do
      new_resource.flags "-f"
      expect(provider.command).to eq(%q{"perl" -f})
    end
  end

  describe "#action_run" do
    before do
      allow(provider).to receive(:stream_to_stdout?).and_return(false)
    end

    it "should call shell_out! with the command and correct options" do
      opts = {
        timeout: 3600,
        returns: 0,
        default_env: false,
        log_level: :info,
        log_tag: "script[run some perl code]",
        input: "$| = 1; print 'i like beans'",
      }

      expect(provider).to receive(:shell_out!).with(provider.command, opts).and_return(true)
      provider.action_run
    end
  end
end
