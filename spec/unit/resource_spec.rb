#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

describe Chef::Resource do
  let(:cookbook_repo_path) { File.join(CHEF_SPEC_DATA, "cookbooks") }
  let(:cookbook_collection) { Chef::CookbookCollection.new(Chef::CookbookLoader.new(cookbook_repo_path)) }
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, cookbook_collection, events) }
  let(:resource) { resource_class.new("funk", run_context) }
  let(:resource_class) { Chef::Resource }

  it "should mixin shell_out" do
    expect(resource.respond_to?(:shell_out)).to be true
  end

  it "should mixin shell_out!" do
    expect(resource.respond_to?(:shell_out!)).to be true
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
    it "has :name as identity attribute by default" do
      expect(Chef::Resource.identity_attr).to eq(:name)
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
    let(:resource_sans_id) { Chef::Resource.new("my-name") }

    # Would rather force identity attributes to be set for everything,
    # but that's not plausible for back compat reasons.
    it "uses the name as the identity" do
      expect(resource_sans_id.identity).to eq("my-name")
    end
  end

  describe "when an identity attribute has been declared" do
    let(:file_resource) do
      file_resource_class = Class.new(Chef::Resource) do
        identity_attr :path
        attr_accessor :path
      end

      file_resource = file_resource_class.new("identity-attr-test")
      file_resource.path = "/tmp/foo.txt"
      file_resource
    end

    it "gives the value of its identity attribute" do
      expect(file_resource.identity).to eq("/tmp/foo.txt")
    end
  end

  describe "when declaring state attributes" do
    it "has no state_attrs by default" do
      expect(Chef::Resource.state_attrs).to be_empty
    end

    it "sets a list of state attributes" do
      resource_class = Class.new(Chef::Resource)
      resource_class.state_attrs(:checksum, :owner, :group, :mode)
      expect(resource_class.state_attrs).to match_array(%i{checksum owner group mode})
    end

    it "inherits state attributes from the superclass" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.state_attrs(:checksum, :owner, :group, :mode)
      expect(resource_subclass.state_attrs).to match_array(%i{checksum owner group mode})
    end

    it "combines inherited state attributes with non-inherited state attributes" do
      resource_class = Class.new(Chef::Resource)
      resource_subclass = Class.new(resource_class)
      resource_class.state_attrs(:checksum, :owner)
      resource_subclass.state_attrs(:group, :mode)
      expect(resource_subclass.state_attrs).to match_array(%i{checksum owner group mode})
    end

  end

  describe "when a set of state attributes has been declared" do
    let(:file_resource) do
      file_resource_class = Class.new(Chef::Resource) do

        state_attrs :checksum, :owner, :group, :mode

        attr_accessor :checksum
        attr_accessor :owner
        attr_accessor :group
        attr_accessor :mode
      end

      file_resource = file_resource_class.new("describe-state-test")
      file_resource.checksum = "abc123"
      file_resource.owner = "root"
      file_resource.group = "wheel"
      file_resource.mode = "0644"
      file_resource
    end

    it "describes its state" do
      resource_state = file_resource.state_for_resource_reporter
      expect(resource_state.keys).to match_array(%i{checksum owner group mode})
      expect(resource_state[:checksum]).to eq("abc123")
      expect(resource_state[:owner]).to eq("root")
      expect(resource_state[:group]).to eq("wheel")
      expect(resource_state[:mode]).to eq("0644")
    end
  end

  describe "#state_for_resource_reporter" do
    context "when a property is marked as sensitive" do
      it "suppresses the sensitive property's value" do
        resource_class = Class.new(Chef::Resource) { property :foo, String, sensitive: true }
        resource = resource_class.new("sensitive_property_tests")
        resource.foo = "some value"
        expect(resource.state_for_resource_reporter[:foo]).to eq("*sensitive value suppressed*")
      end
    end

    context "when a property is not marked as sensitive" do
      it "does not suppress the property's value" do
        resource_class = Class.new(Chef::Resource) { property :foo, String }
        resource = resource_class.new("sensitive_property_tests")
        resource.foo = "some value"
        expect(resource.state_for_resource_reporter[:foo]).to eq("some value")
      end
    end
  end

  describe "load_from" do
    let(:prior_resource) do
      prior_resource = Chef::Resource.new("funk")
      prior_resource.source_line
      prior_resource.allowed_actions << :funkytown
      prior_resource.action(:funkytown)
      prior_resource
    end
    before(:each) do
      resource.allowed_actions << :funkytown
      run_context.resource_collection << prior_resource
    end

    it "should load the attributes of a prior resource" do
      resource.load_from(prior_resource)
    end

    it "should not inherit the action from the prior resource" do
      resource.load_from(prior_resource)
      expect(resource.action).not_to eq(prior_resource.action)
    end
  end

  describe "name" do
    it "should have a name" do
      expect(resource.name).to eql("funk")
    end

    it "should let you set a new name" do
      resource.name "monkey"
      expect(resource.name).to eql("monkey")
    end

    it "coerces arrays to names" do
      expect(resource.name %w{a b}).to eql("a, b")
    end

    it "should coerce objects to a string" do
      expect(resource.name Object.new).to be_a(String)
    end
  end

  describe "notifies" do
    it "should make notified resources appear in the actions hash" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      resource.notifies :reload, run_context.resource_collection.find(zen_master: "coffee")
      expect(resource.delayed_notifications.detect { |e| e.resource.name == "coffee" && e.action == :reload }).not_to be_nil
    end

    it "should make notified resources be capable of acting immediately" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      resource.notifies :reload, run_context.resource_collection.find(zen_master: "coffee"), :immediate
      expect(resource.immediate_notifications.detect { |e| e.resource.name == "coffee" && e.action == :reload }).not_to be_nil
    end

    it "should raise an exception if told to act in other than :delay or :immediate(ly)" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      expect do
        resource.notifies :reload, run_context.resource_collection.find(zen_master: "coffee"), :someday
      end.to raise_error(ArgumentError)
    end

    it "should allow multiple notified resources appear in the actions hash" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      resource.notifies :reload, run_context.resource_collection.find(zen_master: "coffee")
      expect(resource.delayed_notifications.detect { |e| e.resource.name == "coffee" && e.action == :reload }).not_to be_nil

      run_context.resource_collection << Chef::Resource::ZenMaster.new("beans")
      resource.notifies :reload, run_context.resource_collection.find(zen_master: "beans")
      expect(resource.delayed_notifications.detect { |e| e.resource.name == "beans" && e.action == :reload }).not_to be_nil
    end

    it "creates a notification for a resource that is not yet in the resource collection" do
      resource.notifies(:restart, service: "apache")
      expected_notification = Chef::Resource::Notification.new({ service: "apache" }, :restart, resource)
      expect(resource.delayed_notifications).to include(expected_notification)
    end

    it "notifies another resource immediately" do
      resource.notifies_immediately(:restart, service: "apache")
      expected_notification = Chef::Resource::Notification.new({ service: "apache" }, :restart, resource)
      expect(resource.immediate_notifications).to include(expected_notification)
    end

    it "notifies a resource to take action at the end of the chef run" do
      resource.notifies_delayed(:restart, service: "apache")
      expected_notification = Chef::Resource::Notification.new({ service: "apache" }, :restart, resource)
      expect(resource.delayed_notifications).to include(expected_notification)
    end

    it "notifies a resource with an array for its name via its prettified string name" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new(%w{coffee tea})
      resource.notifies :reload, run_context.resource_collection.find(zen_master: "coffee, tea")
      expect(resource.delayed_notifications.detect { |e| e.resource.name == "coffee, tea" && e.action == :reload }).not_to be_nil
    end

    it "notifies a resource without a name via a string name with brackets" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("")
      resource.notifies :reload, "zen_master[]"
    end

    it "notifies a resource without a name via a string name without brackets" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("")
      resource.notifies :reload, "zen_master"
      expect(resource.delayed_notifications.first.resource).to eql("zen_master")
    end

    it "notifies a resource without a name via a hash name with an empty string" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("")
      resource.notifies :reload, zen_master: ""
      expect(resource.delayed_notifications.first.resource).to eql(zen_master: "")
    end
  end

  describe "subscribes" do
    it "should make resources appear in the actions hash of subscribed nodes" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = run_context.resource_collection.find(zen_master: "coffee")
      resource.subscribes :reload, zr
      expect(zr.delayed_notifications.detect { |e| e.resource.name == "funk" && e.action == :reload }).not_to be_nil
    end

    it "should make resources appear in the actions hash of subscribed nodes" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = run_context.resource_collection.find(zen_master: "coffee")
      resource.subscribes :reload, zr
      expect(zr.delayed_notifications.detect { |e| e.resource.name == resource.name && e.action == :reload }).not_to be_nil

      run_context.resource_collection << Chef::Resource::ZenMaster.new("bean")
      zrb = run_context.resource_collection.find(zen_master: "bean")
      zrb.subscribes :reload, zr
      expect(zr.delayed_notifications.detect { |e| e.resource.name == resource.name && e.action == :reload }).not_to be_nil
    end

    it "should make subscribed resources be capable of acting immediately" do
      run_context.resource_collection << Chef::Resource::ZenMaster.new("coffee")
      zr = run_context.resource_collection.find(zen_master: "coffee")
      resource.subscribes :reload, zr, :immediately
      expect(zr.immediate_notifications.detect { |e| e.resource.name == resource.name && e.action == :reload }).not_to be_nil
    end
  end

  describe "defined_at" do
    it "should correctly parse source_line on unix-like operating systems" do
      resource.source_line = "/some/path/to/file.rb:80:in `wombat_tears'"
      expect(resource.defined_at).to eq("/some/path/to/file.rb line 80")
    end

    it "should correctly parse source_line on Windows" do
      resource.source_line = "C:/some/path/to/file.rb:80 in 1`wombat_tears'"
      expect(resource.defined_at).to eq("C:/some/path/to/file.rb line 80")
    end

    it "should include the cookbook and recipe when it knows it" do
      resource.source_line = "/some/path/to/file.rb:80:in `wombat_tears'"
      resource.recipe_name = "wombats"
      resource.cookbook_name = "animals"
      expect(resource.defined_at).to eq("animals::wombats line 80")
    end

    it "should recognize dynamically defined resources" do
      expect(resource.defined_at).to eq("dynamically defined")
    end
  end

  describe "to_s" do
    it "should become a string like resource_name[name]" do
      zm = Chef::Resource::ZenMaster.new("coffee")
      expect(zm.to_s).to eql("zen_master[coffee]")
    end
  end

  describe "to_text" do
    it "prints nice message" do
      resource_class = Class.new(Chef::Resource) { property :foo, String }
      resource = resource_class.new("sensitive_property_tests")
      resource.foo = "some value"
      expect(resource.to_text).to match(/foo "some value"/)
    end

    context "when property is sensitive" do
      it "suppresses that properties value" do
        resource_class = Class.new(Chef::Resource) { property :foo, String, sensitive: true }
        resource = resource_class.new("sensitive_property_tests")
        resource.foo = "some value"
        expect(resource.to_text).to match(/foo "\*sensitive value suppressed\*"/)
      end
    end

    context "when property is required" do
      it "does not propagate validation errors" do
        resource_class = Class.new(Chef::Resource) { property :foo, String, required: true }
        resource = resource_class.new("required_property_tests")
        expect { resource.to_text }.to_not raise_error
      end
    end
  end

  context "Documentation of resources" do
    it "can have a description" do
      c = Class.new(Chef::Resource) do
        description "my description"
      end
      expect(c.description).to eq "my description"
    end

    it "can say when it was introduced" do
      c = Class.new(Chef::Resource) do
        introduced "14.0"
      end
      expect(c.introduced).to eq "14.0"
    end

    it "can have some examples" do
      c = Class.new(Chef::Resource) do
        examples <<~EOH
          resource "foo" do
            foo foo
          end
        EOH
      end
      expect(c.examples).to eq <<~EOH
        resource "foo" do
          foo foo
        end
      EOH
    end
  end

  describe "self.resource_name" do
    context "When resource_name is not set" do
      it "and there are no provides lines, resource_name is nil" do
        c = Class.new(Chef::Resource) do
        end

        r = c.new("hi")
        r.declared_type = :d
        expect(c.resource_name).to be_nil
        expect(r.resource_name).to be_nil
        expect(r.declared_type).to eq :d
      end

      it "and there are no provides lines, resource_name is used" do
        c = Class.new(Chef::Resource) do
          def initialize(*args, &block)
            @resource_name = :blah
            super
          end
        end

        r = c.new("hi")
        r.declared_type = :d
        expect(c.resource_name).to be_nil
        expect(r.resource_name).to eq :blah
        expect(r.declared_type).to eq :d
      end

      it "and the resource class gets a late-bound name, resource_name is nil" do
        c = Class.new(Chef::Resource) do
          def self.name
            "ResourceSpecNameTest"
          end
        end

        r = c.new("hi")
        r.declared_type = :d
        expect(c.resource_name).to be_nil
        expect(r.resource_name).to be_nil
        expect(r.declared_type).to eq :d
      end
    end

    it "resource_name without provides is honored" do
      c = Class.new(Chef::Resource) do
        resource_name "blah"
      end

      r = c.new("hi")
      r.declared_type = :d
      expect(c.resource_name).to eq :blah
      expect(r.resource_name).to eq :blah
      expect(r.declared_type).to eq :d
    end
    it "setting class.resource_name with 'resource_name = blah' overrides declared_type" do
      c = Class.new(Chef::Resource) do
        provides :self_resource_name_test_2
      end
      c.resource_name = :blah

      r = c.new("hi")
      r.declared_type = :d
      expect(c.resource_name).to eq :blah
      expect(r.resource_name).to eq :blah
      expect(r.declared_type).to eq :d
    end
    it "setting class.resource_name with 'resource_name blah' overrides declared_type" do
      c = Class.new(Chef::Resource) do
        resource_name :blah
        provides :self_resource_name_test_3
      end

      r = c.new("hi")
      r.declared_type = :d
      expect(c.resource_name).to eq :blah
      expect(r.resource_name).to eq :blah
      expect(r.declared_type).to eq :d
    end

    # This tests some somewhat confusing behavior that used to occur due to the resource_name call
    # automatically wiring up the old canonical provides line.
    it "setting resoure_name does not override provides in prior resource" do
      c1 = Class.new(Chef::Resource) do
        resource_name :self_resource_name_test_4
        provides :self_resource_name_test_4
      end
      c2 = Class.new(Chef::Resource) do
        resource_name :self_resource_name_test_4
        provides(:self_resource_name_test_4) { false } # simulates any filter that does not match
      end
      expect(Chef::Resource.resource_for_node(:self_resource_name_test_4, node)).to eql(c1)
    end
  end

  describe "to_json" do
    it "should serialize to json" do
      json = resource.to_json
      expect(json).to match(/json_class/)
      expect(json).to match(/instance_vars/)
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { resource }
    end
  end

  describe "to_hash" do
    context "when the resource has a property with a default" do
      let(:resource_class) { Class.new(Chef::Resource) { property :a, default: 1 } }
      it "should include the default in the hash" do
        expect(resource.to_hash.keys.sort).to eq(%i{a allowed_actions params provider updated
          updated_by_last_action before
          name source_line
          action elapsed_time
          default_guard_interpreter guard_interpreter}.sort)
        expect(resource.to_hash[:name]).to eq "funk"
        expect(resource.to_hash[:a]).to eq 1
      end
    end

    it "should convert to a hash" do
      hash = resource.to_hash
      expected_keys = %i{allowed_actions params provider updated
        updated_by_last_action before
        name source_line
        action elapsed_time
        default_guard_interpreter guard_interpreter}
      expect(hash.keys - expected_keys).to eq([])
      expect(expected_keys - hash.keys).to eq([])
      expect(hash[:name]).to eql("funk")
    end
  end

  describe "self.json_create" do
    it "should deserialize itself from json" do
      json = Chef::JSONCompat.to_json(resource)
      serialized_node = Chef::Resource.from_json(json)
      expect(serialized_node).to be_a_kind_of(Chef::Resource)
      expect(serialized_node.name).to eql(resource.name)
    end
  end

  describe "ignore_failure" do
    it "should default to throwing an error if a provider fails for a resource" do
      expect(resource.ignore_failure).to eq(false)
    end

    it "should allow you to set whether a provider should throw exceptions with ignore_failure" do
      resource.ignore_failure(true)
      expect(resource.ignore_failure).to eq(true)
    end

    it "should allow you to set quiet ignore_failure as a symbol" do
      resource.ignore_failure(:quiet)
      expect(resource.ignore_failure).to eq(:quiet)
    end

    it "should allow you to set quiet ignore_failure as a string" do
      resource.ignore_failure("quiet")
      expect(resource.ignore_failure).to eq("quiet")
    end
  end

  describe "retries" do
    let(:retriable_resource) do
      retriable_resource = Chef::Resource::Cat.new("precious", run_context)
      retriable_resource.provider = Chef::Provider::SnakeOil
      retriable_resource.action = :purr
      retriable_resource
    end

    before do
      node.automatic_attrs[:platform] = "fubuntu"
      node.automatic_attrs[:platform_version] = "10.04"
    end

    it "should default to not retrying if a provider fails for a resource" do
      expect(retriable_resource.retries).to eq(0)
    end

    it "should allow you to set how many retries a provider should attempt after a failure" do
      retriable_resource.retries(2)
      expect(retriable_resource.retries).to eq(2)
    end

    it "should default to a retry delay of 2 seconds" do
      expect(retriable_resource.retry_delay).to eq(2)
    end

    it "should allow you to set the retry delay" do
      retriable_resource.retry_delay(10)
      expect(retriable_resource.retry_delay).to eq(10)
    end

    it "should keep given value of retries intact after the provider fails for a resource" do
      retriable_resource.retries(3)
      retriable_resource.retry_delay(0) # No need to wait.

      provider = Chef::Provider::SnakeOil.new(retriable_resource, run_context)
      allow(Chef::Provider::SnakeOil).to receive(:new).and_return(provider)
      allow(provider).to receive(:action_purr).and_raise

      expect(retriable_resource).to receive(:sleep).exactly(3).times
      expect { retriable_resource.run_action(:purr) }.to raise_error(RuntimeError)
      expect(retriable_resource.retries).to eq(3)
    end

    it "should not rescue from non-StandardError exceptions" do
      retriable_resource.retries(3)
      retriable_resource.retry_delay(0) # No need to wait.

      provider = Chef::Provider::SnakeOil.new(retriable_resource, run_context)
      allow(Chef::Provider::SnakeOil).to receive(:new).and_return(provider)
      allow(provider).to receive(:action_purr).and_raise(LoadError)

      expect(retriable_resource).not_to receive(:sleep)
      expect { retriable_resource.run_action(:purr) }.to raise_error(LoadError)
    end
  end

  it "runs an action by finding its provider, loading the current resource and then running the action" do
    skip
  end

  describe "when updated by a provider" do
    before do
      resource.updated_by_last_action(true)
    end

    it "records that it was updated" do
      expect(resource).to be_updated
    end

    it "records that the last action updated the resource" do
      expect(resource).to be_updated_by_last_action
    end

    describe "and then run again without being updated" do
      before do
        resource.updated_by_last_action(false)
      end

      it "reports that it is updated" do
        expect(resource).to be_updated
      end

      it "reports that it was not updated by the last action" do
        expect(resource).not_to be_updated_by_last_action
      end

    end

  end

  describe "when invoking its action" do
    let(:resource) do
      resource = Chef::Resource.new("provided", run_context)
      resource.provider = Chef::Provider::SnakeOil
      resource
    end
    before do
      node.automatic_attrs[:platform] = "fubuntu"
      node.automatic_attrs[:platform_version] = "10.04"
    end

    it "does not run only_if if no only_if command is given" do
      expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:evaluate)
      resource.only_if.clear
      resource.run_action(:purr)
    end

    it "runs runs an only_if when one is given" do
      snitch_variable = nil
      resource.only_if { snitch_variable = true }
      expect(resource.only_if.first.positivity).to eq(:only_if)
      # Chef::Mixin::Command.should_receive(:only_if).with(true, {}).and_return(false)
      resource.run_action(:purr)
      expect(snitch_variable).to be_truthy
    end

    it "runs multiple only_if conditionals" do
      snitch_var1, snitch_var2 = nil, nil
      resource.only_if { snitch_var1 = 1 }
      resource.only_if { snitch_var2 = 2 }
      resource.run_action(:purr)
      expect(snitch_var1).to eq(1)
      expect(snitch_var2).to eq(2)
    end

    it "accepts command options for only_if conditionals" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_command).at_least(1).times
      resource.only_if("true", cwd: "/tmp")
      expect(resource.only_if.first.command_opts).to eq({ cwd: "/tmp" })
      resource.run_action(:purr)
    end

    it "runs not_if as a command when it is a string" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_command).at_least(1).times
      resource.not_if "pwd"
      resource.run_action(:purr)
    end

    it "runs not_if as a block when it is a ruby block" do
      expect_any_instance_of(Chef::Resource::Conditional).to receive(:evaluate_block).at_least(1).times
      resource.not_if { puts "foo" }
      resource.run_action(:purr)
    end

    it "does not run not_if if no not_if command is given" do
      expect_any_instance_of(Chef::Resource::Conditional).not_to receive(:evaluate)
      resource.not_if.clear
      resource.run_action(:purr)
    end

    it "accepts command options for not_if conditionals" do
      resource.not_if("pwd" , cwd: "/tmp")
      expect(resource.not_if.first.command_opts).to eq({ cwd: "/tmp" })
    end

    it "accepts multiple not_if conditionals" do
      snitch_var1, snitch_var2 = true, true
      resource.not_if { snitch_var1 = nil }
      resource.not_if { snitch_var2 = false }
      resource.run_action(:purr)
      expect(snitch_var1).to be_nil
      expect(snitch_var2).to be_falsey
    end

    it "reports 0 elapsed time if actual elapsed time is < 0" do
      expected = Time.now
      allow(Time).to receive(:now).and_return(expected, expected - 1)
      resource.run_action(:purr)
      expect(resource.elapsed_time).to eq(0)
    end

    describe "guard_interpreter attribute" do
      it "should be set to :default by default" do
        expect(resource.guard_interpreter).to eq(:default)
      end

      it "if set to :default should return :default when read" do
        resource.guard_interpreter(:default)
        expect(resource.guard_interpreter).to eq(:default)
      end

      it "should raise Chef::Exceptions::ValidationFailed on an attempt to set the guard_interpreter attribute to something other than a Symbol" do
        expect { resource.guard_interpreter("command_dot_com") }.to raise_error(Chef::Exceptions::ValidationFailed)
      end

      it "should not raise an exception when setting the guard interpreter attribute to a Symbol" do
        allow(Chef::GuardInterpreter::ResourceGuardInterpreter).to receive(:new).and_return(nil)
        expect { resource.guard_interpreter(:command_dot_com) }.not_to raise_error
      end
    end
  end

  describe "should_skip?" do
    before do
      resource = Chef::Resource::Cat.new("sugar", run_context)
    end

    it "should return false by default" do
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return false when only_if is met" do
      resource.only_if { true }
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when only_if is not met" do
      resource.only_if { false }
      expect(resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when not_if is met" do
      resource.not_if { true }
      expect(resource.should_skip?(:purr)).to be_truthy
    end

    it "should return false when not_if is not met" do
      resource.not_if { false }
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when only_if is met but also not_if is met" do
      resource.only_if { true }
      resource.not_if { true }
      expect(resource.should_skip?(:purr)).to be_truthy
    end

    it "should return false when only_if is met and also not_if is not met" do
      resource.only_if { true }
      resource.not_if { false }
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when one of multiple only_if's is not met" do
      resource.only_if { true }
      resource.only_if { false }
      resource.only_if { true }
      expect(resource.should_skip?(:purr)).to be_truthy
    end

    it "should return true when one of multiple not_if's is met" do
      resource.not_if { false }
      resource.not_if { true }
      resource.not_if { false }
      expect(resource.should_skip?(:purr)).to be_truthy
    end

    it "should return false when all of multiple only_if's are met" do
      resource.only_if { true }
      resource.only_if { true }
      resource.only_if { true }
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return false when all of multiple not_if's are not met" do
      resource.not_if { false }
      resource.not_if { false }
      resource.not_if { false }
      expect(resource.should_skip?(:purr)).to be_falsey
    end

    it "should return true when action is :nothing" do
      expect(resource.should_skip?(:nothing)).to be_truthy
    end

    it "should return true when action is :nothing ignoring only_if/not_if conditionals" do
      resource.only_if { true }
      resource.not_if { false }
      expect(resource.should_skip?(:nothing)).to be_truthy
    end

    it "should print \"skipped due to action :nothing\" message for doc formatter when action is :nothing" do
      fdoc = Chef::Formatters.new(:doc, STDOUT, STDERR)
      allow(run_context).to receive(:events).and_return(fdoc)
      expect(fdoc).to receive(:puts).with(" (skipped due to action :nothing)", anything)
      resource.should_skip?(:nothing)
    end

  end

  describe "when resource action is :nothing" do
    let(:resource1) do
      resource1 = Chef::Resource::Cat.new("sugar", run_context)
      resource1.action = :nothing
      resource1
    end
    before do
      node.automatic_attrs[:platform] = "fubuntu"
      node.automatic_attrs[:platform_version] = "10.04"
    end

    it "should not run only_if/not_if conditionals (CHEF-972)" do
      snitch_var1 = 0
      resource1.only_if { snitch_var1 = 1 }
      resource1.not_if { snitch_var1 = 2 }
      resource1.run_action(:nothing)
      expect(snitch_var1).to eq(0)
    end

    it "should run only_if/not_if conditionals when notified to run another action (CHEF-972)" do
      snitch_var1 = snitch_var2 = 0
      runner = Chef::Runner.new(run_context)

      Chef::Provider::SnakeOil.provides :cat

      resource1.only_if { snitch_var1 = 1 }
      resource1.not_if { snitch_var2 = 2 }
      resource2 = Chef::Resource::Cat.new("coffee", run_context)
      resource2.notifies :purr, resource1
      resource2.action = :purr

      run_context.resource_collection << resource1
      run_context.resource_collection << resource2
      runner.converge

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

    it "adds mappings for a single platform" do
      expect(Chef.resource_handler_map).to receive(:set).with(
        :dinobot, Chef::Resource::Klz, { platform: ["autobots"] }
      )
      klz.provides :dinobot, platform: ["autobots"]
    end

    it "adds mappings for multiple platforms" do
      expect(Chef.resource_handler_map).to receive(:set).with(
        :energy, Chef::Resource::Klz, { platform: %w{autobots decepticons} }
      )
      klz.provides :energy, platform: %w{autobots decepticons}
    end

    it "adds mappings for all platforms", ruby: "< 2.7" do
      expect(Chef.resource_handler_map).to receive(:set).with(
        :tape_deck, Chef::Resource::Klz, {}
      )
      klz.provides :tape_deck
    end

    it "adds mappings for all platforms", ruby: ">= 2.7" do
      expect(Chef.resource_handler_map).to receive(:set).with(
        :tape_deck, Chef::Resource::Klz
      )
      klz.provides :tape_deck
    end

  end

  describe "resource_for_node" do
    describe "lookups from the platform map" do
      let(:klz1) { Class.new(Chef::Resource) }

      before(:each) do
        Chef::Resource::Klz1 = klz1
        node = Chef::Node.new
        node.name("bumblebee")
        node.automatic[:platform] = "autobots"
        node.automatic[:platform_version] = "6.1"
        Object.const_set("Soundwave", klz1)
        klz1.provides :soundwave
      end

      after(:each) do
        Object.send(:remove_const, :Soundwave)
        Chef::Resource.send(:remove_const, :Klz1)
      end

      it "returns a resource by short_name if nothing else matches" do
        expect(Chef::Resource.resource_for_node(:soundwave, node)).to eql(klz1)
      end
    end

    describe "lookups from the platform map" do
      let(:klz2) { Class.new(Chef::Resource) }

      before(:each) do
        Chef::Resource::Klz2 = klz2
        node.name("bumblebee")
        node.automatic[:platform] = "autobots"
        node.automatic[:platform_version] = "6.1"
        klz2.provides :dinobot, platform: ["autobots"]
        Object.const_set("Grimlock", klz2)
        klz2.provides :grimlock
      end

      after(:each) do
        Object.send(:remove_const, :Grimlock)
        Chef::Resource.send(:remove_const, :Klz2)
      end

      it "returns a resource by short_name and node" do
        expect(Chef::Resource.resource_for_node(:dinobot, node)).to eql(klz2)
      end
    end

    describe "chef_version constraints and the platform map" do
      let(:klz3) { Class.new(Chef::Resource) }

      it "doesn't wire up the provides when chef_version is < 1" do
        klz3.provides :bulbasaur, chef_version: "< 1.0"  # this should be false
        expect { Chef::Resource.resource_for_node(:bulbasaur, node) }.to raise_error(Chef::Exceptions::NoSuchResourceType)
      end

      it "wires up the provides when chef_version is > 1" do
        klz3.provides :bulbasaur, chef_version: "> 1.0"  # this should be true
        expect(Chef::Resource.resource_for_node(:bulbasaur, node)).to eql(klz3)
      end

      it "wires up the default when chef_version is < 1" do
        klz3.chef_version_for_provides("< 1.0")  # this should be false
        klz3.provides :bulbasaur
        expect { Chef::Resource.resource_for_node(:bulbasaur, node) }.to raise_error(Chef::Exceptions::NoSuchResourceType)
      end

      it "wires up the default when chef_version is > 1" do
        klz3.chef_version_for_provides("> 1.0")  # this should be true
        klz3.provides :bulbasaur
        expect(Chef::Resource.resource_for_node(:bulbasaur, node)).to eql(klz3)
      end
    end

  end

  describe "when creating notifications" do

    describe "with a string resource spec" do

      it "creates a delayed notification when timing is not specified" do
        resource.notifies(:run, "execute[foo]")
        expect(run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates a delayed notification when :delayed is not specified" do
        resource.notifies(:run, "execute[foo]", :delayed)
        expect(run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediate is specified" do
        resource.notifies(:run, "execute[foo]", :immediate)
        expect(run_context.immediate_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediately is specified" do
        resource.notifies(:run, "execute[foo]", :immediately)
        expect(run_context.immediate_notification_collection.size).to eq(1)
      end

      describe "with a syntax error in the resource spec" do

        it "raises an exception immediately" do
          expect do
            resource.notifies(:run, "typo[missing-closing-bracket")
          end.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
        end
      end
    end

    describe "with a resource reference" do
      let(:notified_resource) { Chef::Resource.new("punk", run_context) }

      it "creates a delayed notification when timing is not specified" do
        resource.notifies(:run, notified_resource)
        expect(run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates a delayed notification when :delayed is not specified" do
        resource.notifies(:run, notified_resource, :delayed)
        expect(run_context.delayed_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediate is specified" do
        resource.notifies(:run, notified_resource, :immediate)
        expect(run_context.immediate_notification_collection.size).to eq(1)
      end

      it "creates an immediate notification when :immediately is specified" do
        resource.notifies(:run, notified_resource, :immediately)
        expect(run_context.immediate_notification_collection.size).to eq(1)
      end
    end

  end

  describe "resource sensitive attribute" do
    let(:resource_file) { Chef::Resource::File.new("/nonexistent/CHEF-5098/file", run_context) }
    let(:action) { :create }

    def compiled_resource_data(resource, action, err)
      error_inspector = Chef::Formatters::ErrorInspectors::ResourceFailureInspector.new(resource, action, err)
      description = Chef::Formatters::ErrorDescription.new("test")
      error_inspector.add_explanation(description)
      Chef::Log.info("description: #{description.inspect},error_inspector: #{error_inspector}")
      description.sections[1]["Compiled Resource:"]
    end

    it "set to false by default" do
      expect(resource.sensitive).to be_falsey
    end

    it "when set to false should show compiled resource for failed resource" do
      expect { resource_file.run_action(action) }.to raise_error { |err|
        expect(compiled_resource_data(resource_file, action, err)).to match 'path "/nonexistent/CHEF-5098/file"'
      }
    end

    it "when set to true should show compiled resource for failed resource" do
      resource_file.sensitive true
      expect { resource_file.run_action(action) }.to raise_error { |err|
        expect(compiled_resource_data(resource_file, action, err)).to eql("suppressed sensitive resource output")
      }
    end

  end

  describe "#action" do
    let(:resource_class) do
      Class.new(described_class) do
        allowed_actions(%i{one two})
      end
    end
    let(:resource) { resource_class.new("test", nil) }
    subject { resource.action }

    context "with a no action" do
      it { is_expected.to eq [:nothing] }
    end

    context "with a default action" do
      let(:resource_class) do
        Class.new(described_class) do
          default_action(:one)
        end
      end
      it { is_expected.to eq [:one] }
    end

    context "with a symbol action" do
      before { resource.action(:one) }
      it { is_expected.to eq [:one] }
    end

    context "with a string action" do
      before { resource.action("two") }
      it { is_expected.to eq [:two] }
    end

    context "with an array action" do
      before { resource.action(%i{two one}) }
      it { is_expected.to eq %i{two one} }
    end

    context "with an assignment" do
      before { resource.action = :one }
      it { is_expected.to eq [:one] }
    end

    context "with an array assignment" do
      before { resource.action = %i{two one} }
      it { is_expected.to eq %i{two one} }
    end

    context "with an invalid action" do
      it { expect { resource.action(:three) }.to raise_error Chef::Exceptions::ValidationFailed }
    end

    context "with an invalid assignment action" do
      it { expect { resource.action = :three }.to raise_error Chef::Exceptions::ValidationFailed }
    end
  end

  describe "#action_description" do
    class TestResource < ::Chef::Resource
      action :symbol_action, description: "a symbol test" do; end
      action "string_action", description: "a string test" do; end
      action :base_action0 do; end
      action :base_action1, description: "unmodified base action 1 desc" do; end
      action :base_action2, description: "unmodified base action 2 desc" do; end
      action :base_action3, description: "unmodified base action 3 desc" do; end
    end

    it "returns nil when no description was provided for the action" do
      expect(TestResource.action_description(:base_action0)).to eql(nil)
    end

    context "when action definition is a string" do
      it "returns the description whether a symbol or string is used to look it up" do
        expect(TestResource.action_description("string_action")).to eql("a string test")
        expect(TestResource.action_description(:string_action)).to eql("a string test")
      end
    end

    context "when action definition is a symbol" do
      it "returns the description whether a symbol or string is used to look up" do
        expect(TestResource.action_description("symbol_action")).to eql("a symbol test")
        expect(TestResource.action_description(:symbol_action)).to eql("a symbol test")
      end
    end

    context "when inheriting from an existing resource" do
      class TestResourceChild < TestResource
        action :base_action2, description: "modified base action 2 desc" do; end
        action :base_action3 do; end
      end

      it "returns original description when a described action is not overridden in child resource" do
        expect(TestResourceChild.action_description(:base_action1)).to eq "unmodified base action 1 desc"
      end
      it "returns original description when the child resource overrides an inherited action but NOT its description" do
        expect(TestResourceChild.action_description(:base_action3)).to eq "unmodified base action 3 desc"
      end
      it "returns new description when the child resource overrides an inherited action and its description" do
        expect(TestResourceChild.action_description(:base_action2)).to eq "modified base action 2 desc"
      end
    end
  end

  describe ".default_action" do
    let(:default_action) {}
    let(:resource_class) do
      actions = default_action
      Class.new(described_class) do
        default_action(actions) if actions
      end
    end
    subject { resource_class.default_action }

    context "with no default actions" do
      it { is_expected.to eq [:nothing] }
    end

    context "with a symbol default action" do
      let(:default_action) { :one }
      it { is_expected.to eq [:one] }
    end

    context "with a string default action" do
      let(:default_action) { "one" }
      it { is_expected.to eq [:one] }
    end

    context "with an array default action" do
      let(:default_action) { %i{two one} }
      it { is_expected.to eq %i{two one} }
    end
  end

  describe ".preview_resource" do
    let(:klass) { Class.new(Chef::Resource) }

    before do
      allow(Chef::DSL::Resources).to receive(:add_resource_dsl).with(:test_resource)
    end

    it "defaults to false" do
      expect(klass.preview_resource).to eq false
    end

    it "can be set to true" do
      klass.preview_resource(true)
      expect(klass.preview_resource).to eq true
    end

    it "does not affect provides by default" do
      expect(Chef.resource_handler_map).to receive(:set).with(:test_resource, klass, any_args)
      klass.provides(:test_resource)
    end
  end

  describe "tagged" do
    let(:recipe) do
      Chef::Recipe.new("hjk", "test", run_context)
    end

    describe "with the default node object" do
      let(:node) { Chef::Node.new }

      it "should return false for any tags" do
        expect(resource.tagged?("foo")).to be(false)
      end
    end

    it "should return true from tagged? if node is tagged" do
      recipe.tag "foo"
      expect(resource.tagged?("foo")).to be(true)
    end

    it "should return false from tagged? if node is not tagged" do
      expect(resource.tagged?("foo")).to be(false)
    end
  end

  describe "#with_umask" do
    let(:resource) { Chef::Resource.new("testy testerson") }
    let!(:original_umask) { ::File.umask }

    after do
      ::File.umask(original_umask)
    end

    it "does not affect the umask by default" do
      block_value = nil

      resource.with_umask do
        block_value = ::File.umask
      end

      expect(block_value).to eq(original_umask)
    end

    if windows?
      it "is a no-op on Windows" do
        resource.umask = "0123"

        block_value = nil

        resource.with_umask do
          block_value = ::File.umask
        end

        # Format the returned value so a potential error message is easier to understand.
        actual_value = block_value.to_s(8).rjust(4, "0")

        expect(actual_value).to eq("0000")
      end
    else
      it "changes the umask in the block to the set value" do
        resource.umask = "0123"

        block_value = nil

        resource.with_umask do
          block_value = ::File.umask
        end

        # Format the returned value so a potential error message is easier to understand.
        actual_value = block_value.to_s(8).rjust(4, "0")

        expect(actual_value).to eq("0123")
      end
    end

    it "resets the umask afterwards" do
      resource.umask = "0123"

      resource.with_umask do
        "noop"
      end

      expect(::File.umask).to eq(original_umask)
    end

    it "resets the umask if the block raises an error" do
      resource.umask = "0123"

      expect { resource.with_umask { 1 / 0 } }.to raise_error(ZeroDivisionError)

      expect(::File.umask).to eq(original_umask)
    end
  end
end
