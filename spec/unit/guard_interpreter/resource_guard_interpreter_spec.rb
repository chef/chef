#
# Author:: Adam Edwards (<adamed@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::GuardInterpreter::ResourceGuardInterpreter do
  let(:node) do
    node = Chef::Node.new

    node.default["kernel"] = Hash.new
    node.default["kernel"][:machine] = :x86_64.to_s
    node.automatic[:os] = "windows"
    node
  end

  let(:run_context) { Chef::RunContext.new(node, nil, nil) }

  let(:parent_resource) do
    parent_resource = Chef::Resource.new("powershell_unit_test", run_context)
    allow(parent_resource).to receive(:run_action)
    allow(parent_resource).to receive(:updated).and_return(true)
    parent_resource
  end

  let(:guard_interpreter) { Chef::GuardInterpreter::ResourceGuardInterpreter.new(parent_resource, "echo hi", nil) }

  describe "get_interpreter_resource" do
    it "allows the guard interpreter to be set to Chef::Resource::Script" do
      parent_resource.guard_interpreter(:script)
      expect { guard_interpreter }.not_to raise_error
    end

    it "allows the guard interpreter to be set to Chef::Resource::PowershellScript derived indirectly from Chef::Resource::Script" do
      parent_resource.guard_interpreter(:powershell_script)
      expect { guard_interpreter }.not_to raise_error
    end

    it "raises an exception if guard_interpreter is set to a resource not derived from Chef::Resource::Script" do
      parent_resource.guard_interpreter(:file)
      expect { guard_interpreter }.to raise_error(ArgumentError, "Specified guard interpreter class Chef::Resource::File must be a kind of Chef::Resource::Execute resource")
    end

    context "when the resource cannot be found for the platform" do
      before do
        expect(Chef::Resource).to receive(:resource_for_node).with(:foobar, node).and_return(nil)
      end

      it "raises an exception" do
        parent_resource.guard_interpreter(:foobar)
        expect { guard_interpreter }.to raise_error(ArgumentError, "Specified guard_interpreter resource foobar unknown for this platform")
      end
    end

    it "fails when parent_resource is nil" do
      expect { Chef::GuardInterpreter::ResourceGuardInterpreter.new(nil, "echo hi", nil) }.to raise_error(ArgumentError, /Node for guard resource parent must not be nil/)
    end

  end

  describe "#evaluate" do
    let(:guard_interpreter) { Chef::GuardInterpreter::ResourceGuardInterpreter.new(parent_resource, "echo hi", {}) }
    let(:parent_resource) do
      parent_resource = Chef::Resource.new("execute resource", run_context)
      parent_resource.guard_interpreter(:execute)
      parent_resource
    end

    it "successfully evaluates the resource" do
      expect(guard_interpreter.evaluate).to eq(true)
    end

    it "does not corrupt the run_context of the node" do
      node_run_context_before_guard_execution = parent_resource.run_context
      expect(node_run_context_before_guard_execution.object_id).to eq(parent_resource.node.run_context.object_id)
      guard_interpreter.evaluate
      node_run_context_after_guard_execution = parent_resource.run_context
      expect(node_run_context_after_guard_execution.object_id).to eq(parent_resource.node.run_context.object_id)
    end

    describe "script command opts switch" do
      let(:command_opts) { {} }
      let(:guard_interpreter) { Chef::GuardInterpreter::ResourceGuardInterpreter.new(parent_resource, "exit 0", command_opts) }

      context "resource is a Script" do
        context "and guard_interpreter is a :script" do
          let(:parent_resource) do
            parent_resource = Chef::Resource::Script.new("resource", run_context)
            # Ruby scripts are cross platform to both Linux and Windows
            parent_resource.guard_interpreter(:ruby)
            parent_resource
          end

          let(:shell_out) do
            instance_double(Mixlib::ShellOut, :live_stream => true, :run_command => true, :error! => nil)
          end

          before do
            # TODO for some reason Windows is failing on executing a ruby script
            expect(Mixlib::ShellOut).to receive(:new) do |*args|
              expect(args[0]).to match(/^"ruby"/)
              shell_out
            end
          end

          it "merges to :code" do
            expect(command_opts).to receive(:merge).with({ :code => "exit 0" }).and_call_original
            expect(guard_interpreter.evaluate).to eq(true)
          end
        end

        context "and guard_interpreter is :execute" do
          let(:parent_resource) do
            parent_resource = Chef::Resource::Script.new("resource", run_context)
            parent_resource.guard_interpreter(:execute)
            parent_resource
          end

          it "merges to :code" do
            expect(command_opts).to receive(:merge).with({ :command => "exit 0" }).and_call_original
            expect(guard_interpreter.evaluate).to eq(true)
          end
        end
      end

      context "resource is not a Script" do
        let(:parent_resource) do
          parent_resource = Chef::Resource::Execute.new("resource", run_context)
          parent_resource.guard_interpreter(:execute)
          parent_resource
        end

        it "merges to :command" do
          expect(command_opts).to receive(:merge).with({ :command => "exit 0" }).and_call_original
          expect(guard_interpreter.evaluate).to eq(true)
        end
      end

    end
  end
end
