#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'spec_helper'
require 'ostruct'

describe Chef::Resource::Conditional do
  before do
    Mixlib::ShellOut.any_instance.stub(:run_command).and_return(nil)
    @status = OpenStruct.new(:success? => true)
    Mixlib::ShellOut.any_instance.stub(:status).and_return(@status)
    @parent_resource = Chef::Resource.new(nil, Chef::Node.new)
  end

  it "raises an exception when a guard_interpreter is specified and a block is given" do
    @parent_resource.guard_interpreter :canadian_mounties
    expect { Chef::Resource::Conditional.send(:new, :always, @parent_resource, nil, {}) { True } }.to raise_error(ArgumentError, /does not support blocks/)
  end

  it "raises an exception when neither a block or command is given" do
    expect { Chef::Resource::Conditional.send(:new, :always, @parent_resource, nil, {})}.to raise_error(ArgumentError, /requires either a command or a block/)
  end

  describe "when created as an `only_if`" do
    describe "after running a successful command" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "true")
      end

      it "indicates that resource convergence should continue" do
        @conditional.continue?.should be_true
      end
    end

    describe "after running a negative/false command" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "false")
      end

      it "indicates that resource convergence should not continue" do
        @conditional.continue?.should be_false
      end
    end

    describe 'after running a command which timed out' do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource, "false")
        Chef::GuardInterpreter::DefaultGuardInterpreter.any_instance.stub(:shell_out).and_raise(Chef::Exceptions::CommandTimeout)
      end

      it 'indicates that resource convergence should not continue' do
        @conditional.continue?.should be_false
      end

      it 'should log a warning' do
        Chef::Log.should_receive(:warn).with("Command 'false' timed out")
        @conditional.continue?
      end
    end

    describe "after running a block that returns a truthy value" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { Object.new }
      end

      it "indicates that resource convergence should continue" do
        @conditional.continue?.should be_true
      end
    end

    describe "after running a block that returns a falsey value" do
      before do
        @conditional = Chef::Resource::Conditional.only_if(@parent_resource) { nil }
      end

      it "indicates that resource convergence should not continue" do
        @conditional.continue?.should be_false
      end
    end
  end

  describe "when created as a `not_if`" do
    describe "after running a successful/true command" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, "true")
      end

      it "indicates that resource convergence should not continue" do
        @conditional.continue?.should be_false
      end
    end

    describe "after running a failed/false command" do
      before do
        @status.send("success?=", false)
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource, "false")
      end

      it "indicates that resource convergence should continue" do
        @conditional.continue?.should be_true
      end
    end

    describe 'after running a command which timed out' do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource,  "false")
        Chef::GuardInterpreter::DefaultGuardInterpreter.any_instance.stub(:shell_out).and_raise(Chef::Exceptions::CommandTimeout)
      end

      it 'indicates that resource convergence should continue' do
        @conditional.continue?.should be_true
      end

      it 'should log a warning' do
        Chef::Log.should_receive(:warn).with("Command 'false' timed out")
        @conditional.continue?
      end
    end

    describe "after running a block that returns a truthy value" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { Object.new }
      end

      it "indicates that resource convergence should not continue" do
        @conditional.continue?.should be_false
      end
    end

    describe "after running a block that returns a falsey value" do
      before do
        @conditional = Chef::Resource::Conditional.not_if(@parent_resource) { nil }
      end

      it "indicates that resource convergence should continue" do
        @conditional.continue?.should be_true
      end
    end
  end

end
