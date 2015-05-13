#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2008-2011 Opscode, Inc.
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

class ResourceTestHarness < Chef::Resource
  provider_base Chef::Provider::Package
end

describe Chef::Resource do
  before(:each) do
    @cookbook_repo_path =  File.join(CHEF_SPEC_DATA, 'cookbooks')
    @cookbook_collection = Chef::CookbookCollection.new(Chef::CookbookLoader.new(@cookbook_repo_path))
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    @resource = Chef::Resource.new("funk", @run_context)
  end

  describe "when inherited" do

    it "adds an entry to a list of subclasses" do
      subclass = Class.new(Chef::Resource)
      expect(Chef::Resource.resource_classes).to include(subclass)
    end

    it "keeps track of subclasses of subclasses" do
      subclass = Class.new(Chef::Resource)
      subclass_of_subclass = Class.new(subclass)
      expect(Chef::Resource.resource_classes).to include(subclass_of_subclass)
    end

  end

  describe "when declaring the identity attribute" do
    it "has no identity attribute by default" do
      expect(Chef::Resource.identity_attr).to be_nil
    end

    it "sets an identity attribute" do
      resource_class = Class.new(Chef::Resource)
      resource_class.identity_attr(:path)
      expect(resource_class.identity_attr).to eq(:path)
    end

    it "inherits an identity attribute from a superclass" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.identity_attr(:package_name)
      expect(resource_subclass.identity_attr).to eq(:package_name)
    end

    it "overrides the identity attribute from a superclass when the identity attr is set" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.identity_attr(:package_name)
      resource_subclass.identity_attr(:something_else)
      expect(resource_subclass.identity_attr).to eq(:something_else)
    end
  end

  describe "when no identity attribute has been declared" do
    before do
      @resource_sans_id = Chef::Resource.new("my-name")
    end

    # Would rather force identity attributes to be set for everything,
    # but that's not plausible for back compat reasons.
    it "uses the name as the identity" do
      expect(@resource_sans_id.identity).to eq("my-name")
    end
  end

  describe "when an identity attribute has been declared" do
    before do
      @file_resource_class = Class.new(Chef::Resource) do
        identity_attr :path
        attr_accessor :path
      end

      @file_resource = @file_resource_class.new("identity-attr-test")
      @file_resource.path = "/tmp/foo.txt"
    end

    it "gives the value of its identity attribute" do
      expect(@file_resource.identity).to eq("/tmp/foo.txt")
    end
  end

  describe "when declaring state attributes" do
    it "has no state_attrs by default" do
      expect(Chef::Resource.state_attrs).to be_empty
    end

    it "sets a list of state attributes" do
      resource_class = Class.new(Chef::Resource)
      resource_class.state_attrs(:checksum, :owner, :group, :mode)
      expect(resource_class.state_attrs).to match_array([:checksum, :owner, :group, :mode])
    end

    it "inherits state attributes from the superclass" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.state_attrs(:checksum, :owner, :group, :mode)
      expect(resource_subclass.state_attrs).to match_array([:checksum, :owner, :group, :mode])
    end

    it "combines inherited state attributes with non-inherited state attributes" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.state_attrs(:checksum, :owner)
      resource_subclass.state_attrs(:group, :mode)
      expect(resource_subclass.state_attrs).to match_array([:checksum, :owner, :group, :mode])
    end

  end

  describe "when a set of state attributes has been declared" do
    before do
      @file_resource_class = Class.new(Chef::Resource) do

        state_attrs :checksum, :owner, :group, :mode

        attr_accessor :checksum
        attr_accessor :owner
        attr_accessor :group
        attr_accessor :mode
      end

      @file_resource = @file_resource_class.new("describe-state-test")
      @file_resource.checksum = "abc123"
      @file_resource.owner = "root"
      @file_resource.group = "wheel"
      @file_resource.mode = "0644"
    end

    it "describes its state" do
      resource_state = @file_resource.state
      expect(resource_state.keys).to match_array([:checksum, :owner, :group, :mode])
      expect(resource_state[:checksum]).to eq("abc123")
      expect(resource_state[:owner]).to eq("root")
      expect(resource_state[:group]).to eq("wheel")
      expect(resource_state[:mode]).to eq("0644")
    end
  end

  describe "load_from" do
    before(:each) do
      @prior_resource = Chef::Resource.new("funk")
      @prior_resource.supports(:funky => true)
      @prior_resource.source_line
      @prior_resource.allowed_actions << :funkytown
      @prior_resource.action(:funkytown)
      @resource.allowed_actions << :funkytown
      @run_context.resource_collection << @prior_resource
    end

    it "should load the attributes of a prior resource" do
      @resource.load_from(@prior_resource)
      expect(@resource.supports).to eq({ :funky => true })
    end

    it "should not inherit the action from the prior resource" do
      @resource.load_from(@prior_resource)
      expect(@resource.action).not_to eq(@prior_resource.action)
    end
  end

  describe "name" do
    it "should have a name" do
      expect(@resource.name).to eql("funk")
    end

    it "should let you set a new name" do
      @resource.name "monkey"
      expect(@resource.name).to eql("monkey")
    end

    it "coerces arrays to names" do
      expect(@resource.name ['a', 'b']).to eql('a, b')
    end

    it "should coerce objects to a string" do
      expect(@resource.name Object.new).to be_a(String)
    end
  end

  describe "noop" do
    it "should accept true or false for noop" do
      expect { @resource.noop true }.not_to raise_error
      expect { @resource.noop false }.not_to raise_error
      expect { @resource.noop "eat it" }.to raise_error(ArgumentError)
    end
  end

  describe "notifies" do
    it "should make notified resources appear in the actions hash" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee")
      expect(@resource.delayed_notifications.detect{|e| e.resource.name == "coffee" && e.action == :reload}).not_to be_nil
    end

    it "should make notified resources be capable of acting immediately" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee"), :immediate
      expect(@resource.immediate_notifications.detect{|e| e.resource.name == "coffee" && e.action == :reload}).not_to be_nil
    end

    it "should raise an exception if told to act in other than :delay or :immediate(ly)" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      expect {
        @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee"), :someday
      }.to raise_error(ArgumentError)
    end

    it "should allow multiple notified resources appear in the actions hash" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee")
      expect(@resource.delayed_notifications.detect{|e| e.resource.name == "coffee" && e.action == :reload}).not_to be_nil

      @run_context.resource_collection << Chef::Resource::ZenMaster.new("beans")
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "beans")
      expect(@resource.delayed_notifications.detect{|e| e.resource.name == "beans" && e.action == :reload}).not_to be_nil
    end

    it "creates a notification for a resource that is not yet in the resource collection" do
      @resource.notifies(:restart, :service => 'apache')
      expected_notification = Chef::Resource::Notification.new({:service => "apache"}, :restart, @resource)
      expect(@resource.delayed_notifications).to include(expected_notification)
    end

    it "notifies another resource immediately" do
      @resource.notifies_immediately(:restart, :service => 'apache')
      expected_notification = Chef::Resource::Notification.new({:service => "apache"}, :restart, @resource)
      expect(@resource.immediate_notifications).to include(expected_notification)
    end

    it "notifies a resource to take action at the end of the chef run" do
      @resource.notifies_delayed(:restart, :service => "apache")
      expected_notification = Chef::Resource::Notification.new({:service => "apache"}, :restart, @resource)
      expect(@resource.delayed_notifications).to include(expected_notification)
    end

    it "notifies a resource with an array for its name via its prettified string name" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new(["coffee", "tea"])
      @resource.notifies :reload, @run_context.resource_collection.find(:zen_master => "coffee, tea")
      expect(@resource.delayed_notifications.detect{|e| e.resource.name == "coffee, tea" && e.action == :reload}).not_to be_nil
    end
  end

  describe "subscribes" do
    it "should make resources appear in the actions hash of subscribed nodes" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      expect(zr.delayed_notifications.detect{|e| e.resource.name == "funk" && e.action == :reload}).not_to be_nil
    end

    it "should make resources appear in the actions hash of subscribed nodes" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr
      expect(zr.delayed_notifications.detect{|e| e.resource.name == @resource.name && e.action == :reload}).not_to be_nil

      @run_context.resource_collection << Chef::Resource::ZenMaster.new("bean")
      zrb = @run_context.resource_collection.find(:zen_master => "bean")
      zrb.subscribes :reload, zr
      expect(zr.delayed_notifications.detect{|e| e.resource.name == @resource.name && e.action == :reload}).not_to be_nil
    end

    it "should make subscribed resources be capable of acting immediately" do
      @run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = @run_context.resource_collection.find(:zen_master => "coffee")
      @resource.subscribes :reload, zr, :immediately
      expect(zr.immediate_notifications.detect{|e| e.resource.name == @resource.name && e.action == :reload}).not_to be_nil
    end
  end

  describe "defined_at" do
    it "should correctly parse source_line on unix-like operating systems" do
      @resource.source_line = "/some/path/to/file.rb:80:in `wombat_tears'"
      expect(@resource.defined_at).to eq("/some/path/to/file.rb line 80")
    end

    it "should correctly parse source_line on Windows" do
      @resource.source_line = "C:/some/path/to/file.rb:80 in 1`wombat_tears'"
      expect(@resource.defined_at).to eq("C:/some/path/to/file.rb line 80")
    end

    it "should include the cookbook and recipe when it knows it" do
      @resource.source_line = "/some/path/to/file.rb:80:in `wombat_tears'"
      @resource.recipe_name = "wombats"
      @resource.cookbook_name = "animals"
      expect(@resource.defined_at).to eq("animals::wombats line 80")
    end

    it "should recognize dynamically defined resources" do
      expect(@resource.defined_at).to eq("dynamically defined")
    end
  end

  describe "to_s" do
    it "should become a string like resource_name[name]" do
      zm = Chef::Resource::ZenMaster.new("coffee")
      expect(zm.to_s).to eql("zen_master[coffee]")
    end
  end

  describe "is" do
    it "should return the arguments passed with 'is'" do
      zm = Chef::Resource::ZenMaster.new("coffee")
      expect(zm.is("one", "two", "three")).to eq(%w|one two three|)
    end

    it "should allow arguments preceded by is to methods" do
      @resource.noop(@resource.is(true))
      expect(@resource.noop).to eql(true)
    end
  end

  describe "to_json" do
    it "should serialize to json" do
      json = @resource.to_json
      expect(json).to match(/json_class/)
      expect(json).to match(/instance_vars/)
    end

    include_examples "to_json equalivent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @resource }
    end
  end

  describe "to_hash" do
    it "should convert to a hash" do
      hash = @resource.to_hash
      expected_keys = [ :allowed_actions, :params, :provider, :updated,
        :updated_by_last_action, :before, :supports,
        :noop, :ignore_failure, :name, :source_line,
        :action, :retries, :retry_delay, :elapsed_time,
        :default_guard_interpreter, :guard_interpreter, :sensitive ]
      expect(hash.keys - expected_keys).to eq([])
      expect(expected_keys - hash.keys).to eq([])
      expect(hash[:name]).to eql("funk")
    end
  end

  describe "self.json_create" do
    it "should deserialize itself from json" do
      json = Chef::JSONCompat.to_json(@resource)
      serialized_node = Chef::JSONCompat.from_json(json)
      expect(serialized_node).to be_a_kind_of(Chef::Resource)
      expect(serialized_node.name).to eql(@resource.name)
    end
  end

  describe "supports" do
    it "should allow you to set what features this resource supports" do
      support_hash = { :one => :two }
      @resource.supports(support_hash)
      expect(@resource.supports).to eql(support_hash)
    end

    it "should return the current value of supports" do
      expect(@resource.supports).to eq({})
    end
  end

  describe "ignore_failure" do
    it "should default to throwing an error if a provider fails for a resource" do
      expect(@resource.ignore_failure).to eq(false)
    end

    it "should allow you to set whether a provider should throw exceptions with ignore_failure" do
      @resource.ignore_failure(true)
      expect(@resource.ignore_failure).to eq(true)
    end

    it "should allow you to epic_fail" do
      @resource.epic_fail(true)
      expect(@resource.epic_fail).to eq(true)
    end
  end

  describe "retries" do
    before do
      @retriable_resource = Chef::Resource::Cat.new("precious", @run_context)
      @retriable_resource.provider = Chef::Provider::SnakeOil
      @retriable_resource.action = :purr

      @node.automatic_attrs[:platform] = "fubuntu"
      @node.automatic_attrs[:platform_version] = '10.04'
    end

    it "should default to not retrying if a provider fails for a resource" do
      expect(@retriable_resource.retries).to eq(0)
    end

    it "should allow you to set how many retries a provider should attempt after a failure" do
      @retriable_resource.retries(2)
      expect(@retriable_resource.retries).to eq(2)
    end

    it "should default to a retry delay of 2 seconds" do
      expect(@retriable_resource.retry_delay).to eq(2)
    end

    it "should allow you to set the retry delay" do
      @retriable_resource.retry_delay(10)
      expect(@retriable_resource.retry_delay).to eq(10)
    end

    it "should keep given value of retries intact after the provider fails for a resource" do
      @retriable_resource.retries(3)
      @retriable_resource.retry_delay(0) # No need to wait.

      provider = Chef::Provider::SnakeOil.new(@retriable_resource, @run_context)
      allow(Chef::Provider::SnakeOil).to receive(:new).and_return(provider)
      allow(provider).to receive(:action_purr).and_raise

      expect(@retriable_resource).to receive(:sleep).exactly(3).times
      expect { @retriable_resource.run_action(:purr) }.to raise_error
      expect(@retriable_resource.retries).to eq(3)
    end
  end

  describe "setting the base provider class for the resource" do

    it "defaults to Chef::Provider for the base class" do
      expect(Chef::Resource.provider_base).to eq(Chef::Provider)
    end

    it "allows the base provider to be overriden by a " do
      expect(ResourceTestHarness.provider_base).to eq(Chef::Provider::Package)
    end

  end

  it "runs an action by finding its provider, loading the current resource and then running the action" do
    skip
  end

  describe "when updated by a provider" do
    before do
      @resource.updated_by_last_action(true)
    end

    it "records that it was updated" do
      expect(@resource).to be_updated
    end

    it "records that the last action updated the resource" do
      expect(@resource).to be_updated_by_last_action
    end

    describe "and then run again without being updated" do
      before do
        @resource.updated_by_last_action(false)
      end

      it "reports that it is updated" do
        expect(@resource).to be_updated
      end

      it "reports that it was not updated by the last action" do
        expect(@resource).not_to be_updated_by_last_action
      end

    end

  end

  describe "when invoking its action" do
    before do
      @resource = Chef::Resource.new("provided", @run_context)
      @resource.provider = Chef::Provider::SnakeOil
      @node.automatic_attrs[:platform] = "fubuntu"
      @node.automatic_attrs[:platform_version] = '10.04'
    end

    it "does not run only_if if no only_if command is given" do
      expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:evaluate)
      @resource.only_if.clear
      @resource.run_action(:purr)
    end

    it "runs runs an only_if when one is given" do
      snitch_variable = nil
      @resource.only_if { snitch_variable = true }
      expect(@resource.only_if.first.positivity).to eq(:only_if)
      #Chef::Mixin::Command.should_receive(:only_if).with(true, {}).and_return(false)
      @resource.run_action(:purr)
      expect(snitch_variable).to be_truthy
    end

    it "runs multiple only_if conditionals" do
      snitch_var1, snitch_var2 = nil, nil
      @resource.only_if { snitch_var1 = 1 }
      @resource.only_if { snitch_var2 = 2 }
      @resource.run_action(:purr)
      expect(snitch_var1).to eq(1)
      expect(snitch_var2).to eq(2)
    end

    it "accepts command options for only_if conditionals" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_command).at_least(1).times
      @resource.only_if("true", :cwd => '/tmp')
      expect(@resource.only_if.first.command_opts).to eq({:cwd => '/tmp'})
      @resource.run_action(:purr)
    end

    it "runs not_if as a command when it is a string" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_command).at_least(1).times
      @resource.not_if "pwd"
      @resource.run_action(:purr)
    end

    it "runs not_if as a block when it is a ruby block" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_block).at_least(1).times
      @resource.not_if { puts 'foo' }
      @resource.run_action(:purr)
    end

    it "does not run not_if if no not_if command is given" do
      expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:evaluate)
      @resource.not_if.clear
      @resource.run_action(:purr)
    end

    it "accepts command options for not_if conditionals" do
      @resource.not_if("pwd" , :cwd => '/tmp')
      expect(@resource.not_if.first.command_opts).to eq({:cwd => '/tmp'})
    end

    it "accepts multiple not_if conditionals" do
      snitch_var1, snitch_var2 = true, true
      @resource.not_if {snitch_var1 = nil}
      @resource.not_if {snitch_var2 = false}
      @resource.run_action(:purr)
      expect(snitch_var1).to be_nil
      expect(snitch_var2).to be_falsey
    end

    it "reports 0 elapsed time if actual elapsed time is < 0" do
      expected = Time.now
      allow(Time).to receive(:now).and_return(expected, expected - 1)
      @resource.run_action(:purr)
      expect(@resource.elapsed_time).to eq(0)
    end

    describe "guard_interpreter attribute" do
      let(:resource) { @resource }

      it "should be set to :default by default" do
        expect(resource.guard_interpreter).to eq(:default)
      end

      it "if set to :default should return :default when read" do
        resource.guard_interpreter(:default)
        expect(resource.guard_interpreter).to eq(:default)
      end

      it "should raise Chef::Exceptions::ValidationFailed on an attempt to set the guard_interpreter attribute to something other than a Symbol" do
        expect { resource.guard_interpreter('command_dot_com') }.to raise_error(Chef::Exceptions::ValidationFailed)
      end

      it "should not raise an exception when setting the guard interpreter attribute to a Symbol" do
        allow(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:new).and_return(nil)
        expect { resource.guard_interpreter(:command_dot_com) }.not_to raise_error
      end
    end
  end

  describe "should_skip?" do
    before do
      @resource = Chef::Resource::Cat.new("sugar", @run_context)
    end

    it "should return false by default" do
      expect(@resource.should_skip?(:purr)).to be_falsey
    end

    it "should return false when only_if is met" do
      @resource.only_if { true }
      expect(@resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when only_if is not met" do
      @resource.only_if { false }
      expect(@resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when not_if is met" do
      @resource.not_if { true }
      expect(@resource.should_skip?(:purr)).to be_truthy
    end

    it "should return false when not_if is not met" do
      @resource.not_if { false }
      expect(@resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when only_if is met but also not_if is met" do
      @resource.only_if { true }
      @resource.not_if { true }
      expect(@resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when one of multiple only_if's is not met" do
      @resource.only_if { true }
      @resource.only_if { false }
      @resource.only_if { true }
      expect(@resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when one of multiple not_if's is met" do
      @resource.not_if { false }
      @resource.not_if { true }
      @resource.not_if { false }
      expect(@resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when action is :nothing" do
      expect(@resource.should_skip?(:nothing)).to be_truthy
    end

    it "should return true when action is :nothing ignoring only_if/not_if conditionals" do
      @resource.only_if { true }
      @resource.not_if { false }
      expect(@resource.should_skip?(:nothing)).to be_truthy
    end

    it "should print \"skipped due to action :nothing\" message for doc formatter when action is :nothing" do
      fdoc = Chef::Formatters.new(:doc, STDOUT, STDERR)
      allow(@run_context).to receive(:events).and_return(fdoc)
      expect(fdoc).to receive(:puts).with(" (skipped due to action :nothing)", anything())
      @resource.should_skip?(:nothing)
    end

  end

  describe "when resource action is :nothing" do
    before do
      @resource1 = Chef::Resource::Cat.new("sugar", @run_context)
      @resource1.action = :nothing

      @node.automatic_attrs[:platform] = "fubuntu"
      @node.automatic_attrs[:platform_version] = '10.04'
    end

    it "should not run only_if/not_if conditionals (CHEF-972)" do
      snitch_var1 = 0
      @resource1.only_if { snitch_var1 = 1 }
      @resource1.not_if { snitch_var1 = 2 }
      @resource1.run_action(:nothing)
      expect(snitch_var1).to eq(0)
    end

    it "should run only_if/not_if conditionals when notified to run another action (CHEF-972)" do
      snitch_var1 = snitch_var2 = 0
      @runner = Chef::Runner.new(@run_context)
      Chef::Platform.set(
        :resource => :cat,
        :provider => Chef::Provider::SnakeOil
      )

      @resource1.only_if { snitch_var1 = 1 }
      @resource1.not_if { snitch_var2 = 2 }
      @resource2 = Chef::Resource::Cat.new("coffee", @run_context)
      @resource2.notifies :purr, @resource1
      @resource2.action = :purr

      @run_context.resource_collection << @resource1
      @run_context.resource_collection << @resource2
      @runner.converge

      expect(snitch_var1).to eq(1)
      expect(snitch_var2).to eq(2)
    end
  end

  describe "building the platform map" do

    let(:klz) { Class.new(Chef::Resource) }

    before do
      Chef::Resource::Klz = klz
    end

    after do
      Chef::Resource.send(:remove_const, :Klz)
    end

    it 'adds mappings for a single platform' do
      expect(Chef::Resource::Klz.node_map).to receive(:set).with(
        :dinobot, true, { platform: ['autobots'] }
      )
      klz.provides :dinobot, platform: ['autobots']
    end

    it 'adds mappings for multiple platforms' do
      expect(Chef::Resource::Klz.node_map).to receive(:set).with(
        :energy, true, { platform: ['autobots', 'decepticons']}
      )
      klz.provides :energy, platform: ['autobots', 'decepticons']
    end

    it 'adds mappings for all platforms' do
      expect(Chef::Resource::Klz.node_map).to receive(:set).with(
        :tape_deck, true, {}
      )
      klz.provides :tape_deck
    end

  end

  describe "resource_for_node" do
    describe "lookups from the platform map" do
      let(:klz1) { Class.new(Chef::Resource) }

      before(:each) do
        Chef::Resource::Klz1 = klz1
        @node = Chef::Node.new
        @node.name("bumblebee")
        @node.automatic[:platform] = "autobots"
        @node.automatic[:platform_version] = "6.1"
        Object.const_set('Soundwave', klz1)
        klz1.provides :soundwave
      end

      after(:each) do
        Object.send(:remove_const, :Soundwave)
        Chef::Resource.send(:remove_const, :Klz1)
      end

      it "returns a resource by short_name if nothing else matches" do
        expect(Chef::Resource.resource_for_node(:soundwave, @node)).to eql(klz1)
      end
    end

    describe "lookups from the platform map" do
      let(:klz2) { Class.new(Chef::Resource) }

      before(:each) do
        Chef::Resource::Klz2 = klz2
        @node = Chef::Node.new
        @node.name("bumblebee")
        @node.automatic[:platform] = "autobots"
        @node.automatic[:platform_version] = "6.1"
        klz2.provides :dinobot, :on_platforms => ['autobots']
        Object.const_set('Grimlock', klz2)
        klz2.provides :grimlock
      end

      after(:each) do
        Object.send(:remove_const, :Grimlock)
        Chef::Resource.send(:remove_const, :Klz2)
      end

      it "returns a resource by short_name and node" do
        expect(Chef::Resource.resource_for_node(:dinobot, @node)).to eql(klz2)
      end
    end

  end

  describe "when creating notifications" do

    describe "with a string resource spec" do

      it "creates a delayed notification when timing is not specified" do
        @resource.notifies(:run, "execute[foo]")
        expect(@run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates a delayed notification when :delayed is not specified" do
        @resource.notifies(:run, "execute[foo]", :delayed)
        expect(@run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediate is specified" do
        @resource.notifies(:run, "execute[foo]", :immediate)
        expect(@run_context.immediate_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediately is specified" do
        @resource.notifies(:run, "execute[foo]", :immediately)
        expect(@run_context.immediate_notification_collection.size).to eq(1)
      end

      describe "with a syntax error in the resource spec" do

        it "raises an exception immmediately" do
          expect do
            @resource.notifies(:run, "typo[missing-closing-bracket")
          end.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
        end
      end
    end

    describe "with a resource reference" do
      before do
        @notified_resource = Chef::Resource.new("punk", @run_context)
      end

      it "creates a delayed notification when timing is not specified" do
        @resource.notifies(:run, @notified_resource)
        expect(@run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates a delayed notification when :delayed is not specified" do
        @resource.notifies(:run, @notified_resource, :delayed)
        expect(@run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediate is specified" do
        @resource.notifies(:run, @notified_resource, :immediate)
        expect(@run_context.immediate_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediately is specified" do
        @resource.notifies(:run, @notified_resource, :immediately)
        expect(@run_context.immediate_notification_collection.size).to eq(1)
      end
    end

  end

  describe "resource sensitive attribute" do

    before(:each) do
       @resource_file = Chef::Resource::File.new("/nonexistent/CHEF-5098/file", @run_context)
       @action = :create
    end

    def compiled_resource_data(resource, action, err)
      error_inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(resource, action, err)
      description = Chef::Formatters::ErrorDescription.new("test")
      error_inspector.add_explanation(description)
      Chef::Log.info("descrtiption: #{description.inspect},error_inspector: #{error_inspector}")
      description.sections[1]["Compiled Resource:"]
    end

    it "set to false by default" do
      expect(@resource.sensitive).to be_falsey
    end

    it "when set to false should show compiled resource for failed resource" do
      expect { @resource_file.run_action(@action) }.to raise_error { |err|
            expect(compiled_resource_data(@resource_file, @action, err)).to match 'path "/nonexistent/CHEF-5098/file"'
          }
    end

    it "when set to true should show compiled resource for failed resource" do
      @resource_file.sensitive true
      expect { @resource_file.run_action(@action) }.to raise_error { |err|
            expect(compiled_resource_data(@resource_file, @action, err)).to eql("suppressed sensitive resource output")
          }
    end

  end
end
