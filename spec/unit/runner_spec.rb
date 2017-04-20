
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

class SnitchyProvider < Chef::Provider
  def self.all_actions_called
    @all_actions_called ||= []
  end

  def self.action_called(action)
    all_actions_called << action
  end

  def self.clear_action_record
    @all_actions_called = nil
  end

  def load_current_resource
    true
  end

  def action_first_action
    @new_resource.updated_by_last_action(true)
    self.class.action_called(:first)
  end

  def action_second_action
    @new_resource.updated_by_last_action(true)
    self.class.action_called(:second)
  end

  def action_third_action
    @new_resource.updated_by_last_action(true)
    self.class.action_called(:third)
  end

end

class FailureResource < Chef::Resource

  attr_accessor :action

  def initialize(*args)
    super
    @action = :fail
  end

  def provider
    FailureProvider
  end
end

class FailureProvider < Chef::Provider

  class ChefClientFail < StandardError; end

  def load_current_resource
    true
  end

  def action_fail
    raise ChefClientFail, "chef had an error of some sort"
  end
end

describe Chef::Runner do

  let(:node) do
    node = Chef::Node.new
    node.name "latte"
    node.automatic[:platform] = "mac_os_x"
    node.automatic[:platform_version] = "10.5.1"
    node
  end

  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, Chef::CookbookCollection.new({}), events) }
  let(:first_resource) { Chef::Resource::Cat.new("loulou1", run_context) }
  let(:runner) { Chef::Runner.new(run_context) }

  before do
    run_context.resource_collection << first_resource
  end

  it "runner sets up a pointer back to itself in the run_context" do
    expect(runner).to eql(run_context.runner)
  end

  context "when we are doing dynamic provider resolution" do

    it "should pass each resource in the collection to a provider" do
      expect(run_context.resource_collection).to receive(:execute_each_resource).once
      runner.converge
    end

    it "should use the provider specified by the resource (if it has one)" do
      provider = Chef::Provider::Easy.new(run_context.resource_collection[0], run_context)
      # Expect provider to be called twice, because will fall back to old provider lookup
      expect(run_context.resource_collection[0]).to receive(:provider).twice.and_return(Chef::Provider::Easy)
      expect(Chef::Provider::Easy).to receive(:new).once.and_return(provider)
      runner.converge
    end

    it "should run the action for each resource" do
      provider = Chef::Provider::SnakeOil.new(run_context.resource_collection[0], run_context)
      expect(provider).to receive(:action_sell).once.and_return(true)
      expect(Chef::Provider::SnakeOil).to receive(:new).once.and_return(provider)
      runner.converge
    end

    it "should raise exceptions as thrown by a provider" do
      provider = Chef::Provider::SnakeOil.new(run_context.resource_collection[0], run_context)
      expect(Chef::Provider::SnakeOil).to receive(:new).once.and_return(provider)
      expect(provider).to receive(:action_sell).once.and_raise(ArgumentError)
      expect { runner.converge }.to raise_error(ArgumentError)
    end

    it "should not raise exceptions thrown by providers if the resource has ignore_failure set to true" do
      allow(run_context.resource_collection[0]).to receive(:ignore_failure).and_return(true)
      provider = Chef::Provider::SnakeOil.new(run_context.resource_collection[0], run_context)
      expect(Chef::Provider::SnakeOil).to receive(:new).once.and_return(provider)
      expect(provider).to receive(:action_sell).once.and_raise(ArgumentError)
      expect { runner.converge }.not_to raise_error
    end

    it "should retry with the specified delay if retries are specified" do
      num_retries = 3
      allow(run_context.resource_collection[0]).to receive(:retries).and_return(num_retries)
      provider = Chef::Provider::SnakeOil.new(run_context.resource_collection[0], run_context)
      expect(Chef::Provider::SnakeOil).to receive(:new).exactly(num_retries + 1).times.and_return(provider)
      expect(provider).to receive(:action_sell).exactly(num_retries + 1).times.and_raise(ArgumentError)
      expect(run_context.resource_collection[0]).to receive(:sleep).with(2).exactly(num_retries).times
      expect { runner.converge }.to raise_error(ArgumentError)
    end

    it "should execute immediate actions on changed resources" do
      notifying_resource = Chef::Resource::Cat.new("peanut", run_context)
      notifying_resource.action = :purr # only action that will set updated on the resource

      run_context.resource_collection << notifying_resource
      first_resource.action = :nothing # won't be updated unless notified by other resource

      notifying_resource.notifies(:purr, first_resource, :immediately)

      runner.converge

      expect(first_resource).to be_updated
    end

    it "should follow a chain of actions" do
      first_resource.action = :nothing

      middle_resource = Chef::Resource::Cat.new("peanut", run_context)
      middle_resource.action = :nothing
      run_context.resource_collection << middle_resource
      middle_resource.notifies(:purr, first_resource, :immediately)

      last_resource = Chef::Resource::Cat.new("snuffles", run_context)
      last_resource.action = :purr
      run_context.resource_collection << last_resource
      last_resource.notifies(:purr, middle_resource, :immediately)

      runner.converge

      expect(last_resource).to be_updated   # by action(:purr)
      expect(middle_resource).to be_updated # by notification from last_resource
      expect(first_resource).to be_updated # by notification from middle_resource
    end

    it "should execute delayed actions on changed resources" do
      first_resource.action = :nothing
      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :purr

      run_context.resource_collection << second_resource
      second_resource.notifies(:purr, first_resource, :delayed)

      runner.converge

      expect(first_resource).to be_updated
    end

    it "should execute delayed notifications when a failure occurs in the chef client run" do
      first_resource.action = :nothing
      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :purr

      run_context.resource_collection << second_resource
      second_resource.notifies(:purr, first_resource, :delayed)

      third_resource = FailureResource.new("explode", run_context)
      run_context.resource_collection << third_resource

      expect { runner.converge }.to raise_error(FailureProvider::ChefClientFail)

      expect(first_resource).to be_updated
    end

    it "should execute delayed notifications when a failure occurs in a notification" do
      first_resource.action = :nothing
      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :purr

      run_context.resource_collection << second_resource

      third_resource = FailureResource.new("explode", run_context)
      third_resource.action = :nothing
      run_context.resource_collection << third_resource

      second_resource.notifies(:fail, third_resource, :delayed)
      second_resource.notifies(:purr, first_resource, :delayed)

      expect { runner.converge }.to raise_error(FailureProvider::ChefClientFail)

      expect(first_resource).to be_updated
    end

    it "should execute delayed notifications when a failure occurs in multiple notifications" do
      first_resource.action = :nothing
      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :purr

      run_context.resource_collection << second_resource

      third_resource = FailureResource.new("explode", run_context)
      third_resource.action = :nothing
      run_context.resource_collection << third_resource

      fourth_resource = FailureResource.new("explode again", run_context)
      fourth_resource.action = :nothing
      run_context.resource_collection << fourth_resource

      second_resource.notifies(:fail, third_resource, :delayed)
      second_resource.notifies(:fail, fourth_resource, :delayed)
      second_resource.notifies(:purr, first_resource, :delayed)

      exception = nil
      begin
        runner.converge
      rescue => e
        exception = e
      end
      expect(exception).to be_a(Chef::Exceptions::MultipleFailures)

      expected_message = <<-E
Multiple failures occurred:
* FailureProvider::ChefClientFail occurred in delayed notification: [explode] (dynamically defined) had an error: FailureProvider::ChefClientFail: chef had an error of some sort
* FailureProvider::ChefClientFail occurred in delayed notification: [explode again] (dynamically defined) had an error: FailureProvider::ChefClientFail: chef had an error of some sort
      E
      expect(exception.message).to eq(expected_message)

      expect(first_resource).to be_updated
    end

    it "does not duplicate delayed notifications" do
      SnitchyProvider.clear_action_record

      first_resource.action = :nothing
      first_resource.provider = SnitchyProvider

      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :first_action
      second_resource.provider = SnitchyProvider
      run_context.resource_collection << second_resource

      third_resource = Chef::Resource::Cat.new("snickers", run_context)
      third_resource.action = :first_action
      third_resource.provider = SnitchyProvider
      run_context.resource_collection << third_resource

      second_resource.notifies(:second_action, first_resource, :delayed)
      second_resource.notifies(:third_action, first_resource, :delayed)

      third_resource.notifies(:second_action, first_resource, :delayed)
      third_resource.notifies(:third_action, first_resource, :delayed)

      runner.converge
      # resources 2 and 3 call :first_action in the course of normal resource
      # execution, and schedule delayed actions :second and :third on the first
      # resource. The duplicate actions should "collapse" to a single notification
      # and order should be preserved.
      expect(SnitchyProvider.all_actions_called).to eq([:first, :first, :second, :third])
    end

    it "executes delayed notifications in the order they were declared" do
      SnitchyProvider.clear_action_record

      first_resource.action = :nothing
      first_resource.provider = SnitchyProvider

      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :first_action
      second_resource.provider = SnitchyProvider
      run_context.resource_collection << second_resource

      third_resource = Chef::Resource::Cat.new("snickers", run_context)
      third_resource.action = :first_action
      third_resource.provider = SnitchyProvider
      run_context.resource_collection << third_resource

      second_resource.notifies(:second_action, first_resource, :delayed)
      second_resource.notifies(:second_action, first_resource, :delayed)

      third_resource.notifies(:third_action, first_resource, :delayed)
      third_resource.notifies(:third_action, first_resource, :delayed)

      runner.converge
      expect(SnitchyProvider.all_actions_called).to eq([:first, :first, :second, :third])
    end

    it "does not fire notifications if the resource was not updated by the last action executed" do
      # REGRESSION TEST FOR CHEF-1452
      SnitchyProvider.clear_action_record

      first_resource.action = :first_action
      first_resource.provider = SnitchyProvider

      second_resource = Chef::Resource::Cat.new("peanut", run_context)
      second_resource.action = :nothing
      second_resource.provider = SnitchyProvider
      run_context.resource_collection << second_resource

      third_resource = Chef::Resource::Cat.new("snickers", run_context)
      third_resource.action = :nothing
      third_resource.provider = SnitchyProvider
      run_context.resource_collection << third_resource

      first_resource.notifies(:second_action, second_resource, :immediately)
      second_resource.notifies(:third_action, third_resource, :immediately)

      runner.converge

      # All of the resources should only fire once:
      expect(SnitchyProvider.all_actions_called).to eq([:first, :second, :third])

      # all of the resources should be marked as updated for reporting purposes
      expect(first_resource).to be_updated
      expect(second_resource).to be_updated
      expect(third_resource).to be_updated
    end

    it "should check a resource's only_if and not_if if notified by another resource" do
      first_resource.action = :buy

      only_if_called_times = 0
      first_resource.only_if { only_if_called_times += 1; true }

      not_if_called_times = 0
      first_resource.not_if { not_if_called_times += 1; false }

      second_resource = Chef::Resource::Cat.new("carmel", run_context)
      run_context.resource_collection << second_resource
      second_resource.notifies(:purr, first_resource, :delayed)
      second_resource.action = :purr

      # hits only_if first time when the resource is run in order, second on notify
      runner.converge

      expect(only_if_called_times).to eq(2)
      expect(not_if_called_times).to eq(2)
    end

    it "should resolve resource references in notifications when resources are defined lazily" do
      first_resource.action = :nothing

      lazy_resources = lambda do
        last_resource = Chef::Resource::Cat.new("peanut", run_context)
        run_context.resource_collection << last_resource
        last_resource.notifies(:purr, first_resource.to_s, :delayed)
        last_resource.action = :purr
      end
      second_resource = Chef::Resource::RubyBlock.new("myblock", run_context)
      run_context.resource_collection << second_resource
      second_resource.block { lazy_resources.call }

      runner.converge

      expect(first_resource).to be_updated
    end

  end
end
