#
# Author:: Adam Jacob (<adam@chef.io>)
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

class NoWhyrunDemonstrator < Chef::Provider
  attr_reader :system_state_altered

  def whyrun_supported?
    false
  end

  def load_current_resource; end

  def action_foo
    @system_state_altered = true
  end
end

class ConvergeActionDemonstrator < Chef::Provider
  attr_reader :system_state_altered

  def whyrun_supported?
    true
  end

  def load_current_resource; end

  def action_foo
    converge_by("running a state changing action") do
      @system_state_altered = true
    end
  end
end

class CheckResourceSemanticsDemonstrator < ConvergeActionDemonstrator
  def check_resource_semantics!
    raise Chef::Exceptions::InvalidResourceSpecification.new("check_resource_semantics!")
  end
end

describe Chef::Provider do
  before(:each) do
    @cookbook_collection = Chef::CookbookCollection.new([])
    @node = Chef::Node.new
    @node.name "latte"
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    @resource = Chef::Resource.new("funk", @run_context)
    @resource.cookbook_name = "a_delicious_pie"
    @provider = Chef::Provider.new(@resource, @run_context)
  end

  it "should mixin shell_out" do
    expect(@provider.respond_to?(:shell_out)).to be true
  end

  it "should mixin shell_out!" do
    expect(@provider.respond_to?(:shell_out!)).to be true
  end

  it "should store the resource passed to new as new_resource" do
    expect(@provider.new_resource).to eql(@resource)
  end

  it "should store the node passed to new as node" do
    expect(@provider.node).to eql(@node)
  end

  it "should have nil for current_resource by default" do
    expect(@provider.current_resource).to eql(nil)
  end

  it "should support whyrun by default" do
    expect(@provider.send(:whyrun_supported?)).to eql(true)
  end

  it "should do nothing for check_resource_semantics! by default" do
    expect { @provider.check_resource_semantics! }.not_to raise_error
  end

  it "should return true for action_nothing" do
    expect(@provider.action_nothing).to eql(true)
  end

  it "evals embedded recipes with a pristine resource collection" do
    @provider.run_context.instance_variable_set(:@resource_collection, "doesn't matter what this is")
    temporary_collection = nil
    snitch = Proc.new { temporary_collection = @run_context.resource_collection }
    @provider.send(:recipe_eval, &snitch)
    expect(temporary_collection).to be_an_instance_of(Chef::ResourceCollection)
    expect(@provider.run_context.instance_variable_get(:@resource_collection)).to eq("doesn't matter what this is")
  end

  it "does not re-load recipes when creating the temporary run context" do
    expect_any_instance_of(Chef::RunContext).not_to receive(:load)
    snitch = Proc.new { temporary_collection = @run_context.resource_collection }
    @provider.send(:recipe_eval, &snitch)
  end

  context "when no converge actions are queued" do
    before do
      allow(@provider).to receive(:whyrun_supported?).and_return(true)
      allow(@provider).to receive(:load_current_resource)
    end

    it "does not mark the new resource as updated" do
      expect(@resource).not_to be_updated
      expect(@resource).not_to be_updated_by_last_action
    end
  end

  context "when converge actions have been added to the queue" do
    describe "and provider supports whyrun mode" do
      before do
        @provider = ConvergeActionDemonstrator.new(@resource, @run_context)
      end

      it "should tell us that it does support whyrun" do
        expect(@provider).to be_whyrun_supported
      end

      it "queues up converge actions" do
        @provider.action_foo
        expect(@provider.send(:converge_actions).actions.size).to eq(1)
      end

      it "executes pending converge actions to converge the system" do
        @provider.run_action(:foo)
        expect(@provider.instance_variable_get(:@system_state_altered)).to be_truthy
      end

      it "marks the resource as updated" do
        @provider.run_action(:foo)
        expect(@resource).to be_updated
        expect(@resource).to be_updated_by_last_action
      end
    end

    describe "and provider does not support whyrun mode" do
      before do
        Chef::Config[:why_run] = true
        @provider = NoWhyrunDemonstrator.new(@resource, @run_context)
      end

      after do
        Chef::Config[:why_run] = false
      end

      it "should tell us that it doesn't support whyrun" do
        expect(@provider).not_to be_whyrun_supported
      end

      it "should automatically generate a converge_by block on the provider's behalf" do
        @provider.run_action(:foo)
        expect(@provider.send(:converge_actions).actions.size).to eq(0)
        expect(@provider.system_state_altered).to be_falsey
      end

      it "should automatically execute the generated converge_by block" do
        @provider.run_action(:foo)
        expect(@provider.system_state_altered).to be_falsey
        expect(@resource).not_to be_updated
        expect(@resource).not_to be_updated_by_last_action
      end
    end

    describe "and the resource is invalid" do
      let(:provider) { CheckResourceSemanticsDemonstrator.new(@resource, @run_context) }

      it "fails with InvalidResourceSpecification when run" do
        expect { provider.run_action(:foo) }.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
      end

    end
  end
end
