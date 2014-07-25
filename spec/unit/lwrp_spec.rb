#
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

module LwrpConstScopingConflict
end

describe "LWRP" do
  before do
    @original_VERBOSE = $VERBOSE
    $VERBOSE = nil
  end

  after do
    $VERBOSE = @original_VERBOSE
  end

  describe "when overriding an existing class" do
    before :each do
      $stderr.stub(:write)
    end

    it "should log if attempting to load resource of same name" do
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end

      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Log.should_receive(:info).with(/overriding/)
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "should log if attempting to load provider of same name" do
      Dir[File.expand_path( "lwrp/providers/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, nil)
      end

      Dir[File.expand_path( "lwrp/providers/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Log.should_receive(:info).with(/overriding/)
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "removes the old LRWP resource class from the list of resource subclasses [CHEF-3432]" do
      # CHEF-3432 regression test:
      # Chef::Resource keeps a list of all subclasses to assist class inflation
      # for json parsing (see Chef::JSONCompat). When replacing LWRP resources,
      # we need to ensure the old resource class is remove from that list.
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
      first_lwr_foo_class = Chef::Resource::LwrpFoo
      Chef::Resource.resource_classes.should include(first_lwr_foo_class)
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
      Chef::Resource.resource_classes.should_not include(first_lwr_foo_class)
    end

    it "does not attempt to remove classes from higher up namespaces [CHEF-4117]" do
      conflicting_lwrp_file = File.expand_path( "lwrp_const_scoping/resources/conflict.rb", CHEF_SPEC_DATA)
      # The test is that this should not raise an error:
      Chef::Resource::LWRPBase.build_from_file("lwrp_const_scoping", conflicting_lwrp_file, nil)
    end

  end

  describe "Lightweight Chef::Resource" do

    before do
      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp_override", "resources", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "should load the resource into a properly-named class" do
      Chef::Resource.const_get("LwrpFoo").should be_kind_of(Class)
    end

    it "should set resource_name" do
      Chef::Resource::LwrpFoo.new("blah").resource_name.should eql(:lwrp_foo)
    end

    it "should add the specified actions to the allowed_actions array" do
      Chef::Resource::LwrpFoo.new("blah").allowed_actions.should include(:pass_buck, :twiddle_thumbs)
    end

    it "should set the specified action as the default action" do
      Chef::Resource::LwrpFoo.new("blah").action.should == :pass_buck
    end

    it "should create a method for each attribute" do
      Chef::Resource::LwrpFoo.new("blah").methods.map{ |m| m.to_sym}.should include(:monkey)
    end

    it "should build attribute methods that respect validation rules" do
      lambda { Chef::Resource::LwrpFoo.new("blah").monkey(42) }.should raise_error(ArgumentError)
    end

    it "should have access to the run context and node during class definition" do
      node = Chef::Node.new
      node.normal[:penguin_name] = "jackass"
      run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new, @events)

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources_with_default_attributes", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, run_context)
      end

      cls = Chef::Resource.const_get("LwrpNodeattr")
      cls.node.should be_kind_of(Chef::Node)
      cls.run_context.should be_kind_of(Chef::RunContext)
      cls.node[:penguin_name].should eql("jackass")
    end

    context "resource_name" do
      let(:klass) { Class.new(Chef::Resource::LWRPBase) }

      it "returns nil when the resource_name is not set" do
        expect(klass.resource_name).to be_nil
      end

      it "allows to user to user the resource_name" do
        expect {
          klass.resource_name(:foo)
        }.to_not raise_error
      end

      it "returns the set value for the resource" do
        klass.resource_name(:foo)
        expect(klass.resource_name).to eq(:foo)
      end

      context "when creating a new instance" do
        it "raises an exception if resource_name is nil" do
          expect {
            klass.new('blah')
          }.to raise_error(Chef::Exceptions::InvalidResourceSpecification)
        end
      end

      context "lazy default values" do
        let(:klass) do
          Class.new(Chef::Resource::LWRPBase) do
            self.resource_name = :sample_resource
            attribute :food,  :default => lazy { 'BACON!'*3 }
            attribute :drink, :default => lazy { |r| "Drink after #{r.food}!"}
          end
        end

        let(:instance) { klass.new('kitchen') }

        it "evaluates the default value when requested" do
          expect(instance.food).to eq('BACON!BACON!BACON!')
        end

        it "evaluates yields self to the block" do
          expect(instance.drink).to eq('Drink after BACON!BACON!BACON!!')
        end
      end
    end

    describe "when #default_action is an array" do
      let(:lwrp) do
        Class.new(Chef::Resource::LWRPBase) do
          actions :eat, :sleep
          default_action [:eat, :sleep]
        end
      end

      it "returns the array of default actions" do
        expect(lwrp.default_action).to eq([:eat, :sleep])
      end
    end

    describe "when inheriting from LWRPBase" do
      let(:parent) do
        Class.new(Chef::Resource::LWRPBase) do
          actions :eat, :sleep
          default_action :eat
        end
      end

      context "when the child does not defined the methods" do
        let(:child) do
          Class.new(parent)
        end

        it "delegates #actions to the parent" do
          expect(child.actions).to eq([:eat, :sleep])
        end

        it "delegates #default_action to the parent" do
          expect(child.default_action).to eq(:eat)
        end
      end

      context "when the child does define the methods" do
        let(:child) do
          Class.new(parent) do
            actions :dont_eat, :dont_sleep
            default_action :dont_eat
          end
        end

        it "does not delegate #actions to the parent" do
          expect(child.actions).to eq([:dont_eat, :dont_sleep])
        end

        it "does not delegate #default_action to the parent" do
          expect(child.default_action).to eq(:dont_eat)
        end
      end
    end

  end

  describe "Lightweight Chef::Provider" do
    before do
      @node = Chef::Node.new
      @node.automatic[:platform] = :ubuntu
      @node.automatic[:platform_version] = '8.10'
      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(@node, Chef::CookbookCollection.new({}), @events)
      @runner = Chef::Runner.new(@run_context)
    end

    before(:each) do
      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, @run_context)
      end

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp_override", "resources", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, @run_context)
      end

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "providers", "*"))].each do |file|
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, @run_context)
      end

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp_override", "providers", "*"))].each do |file|
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, @run_context)
      end

    end

    it "should properly handle a new_resource reference" do
      resource = Chef::Resource::LwrpFoo.new("morpheus")
      resource.monkey("bob")
      resource.provider(:lwrp_monkey_name_printer)
      resource.run_context = @run_context

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      provider.action_twiddle_thumbs
    end

    it "should load the provider into a properly-named class" do
      Chef::Provider.const_get("LwrpBuckPasser").should be_kind_of(Class)
    end

    it "should create a method for each attribute" do
      new_resource = double("new resource").as_null_object
      Chef::Provider::LwrpBuckPasser.new(nil, new_resource).methods.map{|m|m.to_sym}.should include(:action_pass_buck)
      Chef::Provider::LwrpThumbTwiddler.new(nil, new_resource).methods.map{|m|m.to_sym}.should include(:action_twiddle_thumbs)
    end

    it "should insert resources embedded in the provider into the middle of the resource collection" do
      injector = Chef::Resource::LwrpFoo.new("morpheus", @run_context)
      injector.action(:pass_buck)
      injector.provider(:lwrp_buck_passer)
      dummy = Chef::Resource::ZenMaster.new("keanu reeves", @run_context)
      dummy.provider(Chef::Provider::Easy)
      @run_context.resource_collection.insert(injector)
      @run_context.resource_collection.insert(dummy)

      Chef::Runner.new(@run_context).converge

      @run_context.resource_collection[0].should eql(injector)
      @run_context.resource_collection[1].name.should eql(:prepared_thumbs)
      @run_context.resource_collection[2].name.should eql(:twiddled_thumbs)
      @run_context.resource_collection[3].should eql(dummy)
    end

    it "should insert embedded resources from multiple providers, including from the last position, properly into the resource collection" do
      injector = Chef::Resource::LwrpFoo.new("morpheus", @run_context)
      injector.action(:pass_buck)
      injector.provider(:lwrp_buck_passer)

      injector2 = Chef::Resource::LwrpBar.new("tank", @run_context)
      injector2.action(:pass_buck)
      injector2.provider(:lwrp_buck_passer_2)

      dummy = Chef::Resource::ZenMaster.new("keanu reeves", @run_context)
      dummy.provider(Chef::Provider::Easy)

      @run_context.resource_collection.insert(injector)
      @run_context.resource_collection.insert(dummy)
      @run_context.resource_collection.insert(injector2)

      Chef::Runner.new(@run_context).converge

      @run_context.resource_collection[0].should eql(injector)
      @run_context.resource_collection[1].name.should eql(:prepared_thumbs)
      @run_context.resource_collection[2].name.should eql(:twiddled_thumbs)
      @run_context.resource_collection[3].should eql(dummy)
      @run_context.resource_collection[4].should eql(injector2)
      @run_context.resource_collection[5].name.should eql(:prepared_eyes)
      @run_context.resource_collection[6].name.should eql(:dried_paint_watched)
    end

    it "should properly handle a new_resource reference" do
      resource = Chef::Resource::LwrpFoo.new("morpheus", @run_context)
      resource.monkey("bob")
      resource.provider(:lwrp_monkey_name_printer)

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      provider.action_twiddle_thumbs

      provider.monkey_name.should == "my monkey's name is 'bob'"
    end

    it "should properly handle an embedded Resource accessing the enclosing Provider's scope" do
      resource = Chef::Resource::LwrpFoo.new("morpheus", @run_context)
      resource.monkey("bob")
      resource.provider(:lwrp_embedded_resource_accesses_providers_scope)

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      #provider = @runner.build_provider(resource)
      provider.action_twiddle_thumbs

      provider.enclosed_resource.monkey.should == 'bob, the monkey'
    end

    describe "when using inline compilation" do
      before do
        # Behavior in these examples depends on implementation of fixture provider.
        # See spec/data/lwrp/providers/inline_compiler

        # Side effect of lwrp_inline_compiler provider for testing notifications.
        $interior_ruby_block_2 = nil
        # resource type doesn't matter, so make an existing resource type work with provider.
        @resource = Chef::Resource::LwrpFoo.new("morpheus", @run_context)
        @resource.allowed_actions << :test
        @resource.action(:test)
        @resource.provider(:lwrp_inline_compiler)
      end

      it "does not add interior resources to the exterior resource collection" do
        @resource.run_action(:test)
        @run_context.resource_collection.should be_empty
      end

      context "when interior resources are updated" do
        it "processes notifications within the LWRP provider's action" do
          @resource.run_action(:test)
          $interior_ruby_block_2.should == "executed"
        end

        it "marks the parent resource updated" do
          @resource.run_action(:test)
          @resource.should be_updated
          @resource.should be_updated_by_last_action
        end
      end

      context "when interior resources are not updated" do
        it "does not mark the parent resource updated" do
          @resource.run_action(:no_updates)
          @resource.should_not be_updated
          @resource.should_not be_updated_by_last_action
        end
      end

    end

  end

end
