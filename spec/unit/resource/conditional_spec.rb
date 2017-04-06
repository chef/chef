#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2011-2017, Chef Software Inc.
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
require "ostruct"

describe Chef::Resource::Conditional do
  before do
    allow_any_instance_of(Mixlib::ShellOut).to receive(:run_command).and_return(nil)
    @status = OpenStruct.new(:success? => true)
    allow_any_instance_of(Mixlib::ShellOut).to receive(:status).and_return(@status)
    @parent_resource = Chef::Resource.new("", Chef::Node.new)
  end

  it "raises an exception when neither a block or command is given" do
    expect { Chef::Resource::Conditional.send(:new, :always, @parent_resource, nil, {}) }.to raise_error(ArgumentError, /requires either a command or a block/)
  end

  it "does not evaluate a guard interpreter on initialization of the conditional" do
    expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:configure)
    expect(Chef::GuardInterpreter::DefaultGuardInterpreter).not_to receive(:new)
    expect(Chef::GuardInterpreter::ResourceGuardInterpreter).not_to receive(:new)
    Chef::Resource::Conditional.only_if(@parent_resource, "true")
  end

  describe "configure" do
    it "raises an exception when a guard_interpreter is specified and a block is given" do
      @parent_resource.guard_interpreter :canadian_mounties
      conditional = Chef::Resource::Conditional.send(:new, :always, @parent_resource, nil, {}) { True }
      expect { conditional.configure }.to raise_error(ArgumentError, /does not support blocks/)
    end
  end

  describe "when created as an `only_if`" do
    describe "after running a successful command given as a string" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "true")
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be_truthy
      end
    end

    describe "after running a negative/false command given as a string" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "false")
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be_falsey
      end
    end

    describe "after running a successful command given as an array" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, ["true"])
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be true
      end
    end

    describe "after running a negative/false command given as an array" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, ["false"])
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be false
      end
    end

    describe "after running a command which timed out" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "false")
        allow_any_instance_of(Chef::GuardInterpreter::DefaultGuardInterpreter).to receive(:shell_out_with_systems_locale).and_raise(Chef::Exceptions::CommandTimeout)
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be_falsey
      end

      it "should log a warning" do
        expect(Chef::Log).to receive(:warn).with("Command 'false' timed out")
        @conditional.continue?
      end
    end

    describe "after running a block that returns a truthy value" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { Object.new }
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be_truthy
      end
    end

    describe "after running a block that returns a falsey value" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { nil }
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be_falsey
      end
    end

    describe "after running a block that returns a string value" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { "some command" }
      end

      it "logs a warning" do
        expect(Chef::Log).to receive(:warn).with("only_if block for [] returned \"some command\", did you mean to run a command? If so use 'only_if \"some command\"' in your code.")
        @conditional.evaluate
      end
    end

    describe "after running a block that returns a string value on a sensitive resource" do
      before do
        @parent_resource.sensitive(true)
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { "some command" }
      end

      it "logs a warning" do
        expect(Chef::Log).to receive(:warn).with("only_if block for [] returned a string, did you mean to run a command?")
        @conditional.evaluate
      end
    end
  end

  describe "when created as a `not_if`" do
    describe "after running a successful/true command given as a string" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, "true")
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be_falsey
      end
    end

    describe "after running a failed/false command given as a string" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, "false")
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be_truthy
      end
    end

    describe "after running a successful/true command given as an array" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, ["true"])
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be false
      end
    end

    describe "after running a failed/false command given as an array" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, ["false"])
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be true
      end
    end

    describe "after running a command which timed out" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, "false")
        allow_any_instance_of(Chef::GuardInterpreter::DefaultGuardInterpreter).to receive(:shell_out_with_systems_locale).and_raise(Chef::Exceptions::CommandTimeout)
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be_truthy
      end

      it "should log a warning" do
        expect(Chef::Log).to receive(:warn).with("Command 'false' timed out")
        @conditional.continue?
      end
    end

    describe "after running a block that returns a truthy value" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { Object.new }
      end

      it "indicates that resource convergence should not continue" do
        expect(@conditional.continue?).to be_falsey
      end
    end

    describe "after running a block that returns a falsey value" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { nil }
      end

      it "indicates that resource convergence should continue" do
        expect(@conditional.continue?).to be_truthy
      end
    end

    describe "after running a block that returns a string value" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { "some command" }
      end

      it "logs a warning" do
        expect(Chef::Log).to receive(:warn).with("not_if block for [] returned \"some command\", did you mean to run a command? If so use 'not_if \"some command\"' in your code.")
        @conditional.evaluate
      end
    end

    describe "after running a block that returns a string value on a sensitive resource" do
      before do
        @parent_resource.sensitive(true)
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { "some command" }
      end

      it "logs a warning" do
        expect(Chef::Log).to receive(:warn).with("not_if block for [] returned a string, did you mean to run a command?")
        @conditional.evaluate
      end
    end
  end
end
