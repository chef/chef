#
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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
require "tmpdir"
require "fileutils"
require "chef/mixin/convert_to_class_name"

module LwrpConstScopingConflict
end

describe "LWRP" do
  include Chef::Mixin::ConvertToClassName

  before do
    @original_VERBOSE = $VERBOSE
    $VERBOSE = nil
    Chef::Resource::LWRPBase.class_eval { @loaded_lwrps = {} }
  end

  after do
    $VERBOSE = @original_VERBOSE
  end

  def get_lwrp(name)
    Chef::ResourceResolver.resolve(name)
  end

  def get_lwrp_provider(name)
    old_treat_deprecation_warnings_as_errors = Chef::Config[:treat_deprecation_warnings_as_errors]
    Chef::Config[:treat_deprecation_warnings_as_errors] = false
    begin
      Chef::Provider.const_get(convert_to_class_name(name.to_s))
    ensure
      Chef::Config[:treat_deprecation_warnings_as_errors] = old_treat_deprecation_warnings_as_errors
    end
  end

  describe "when overriding an existing class" do
    before :each do
      allow($stderr).to receive(:write)
    end

    it "should not skip loading a resource when there's a top level symbol of the same name" do
      Object.const_set("LwrpFoo", Class.new)
      file = File.expand_path( "lwrp/resources/foo.rb", CHEF_SPEC_DATA)
      expect(Chef::Log).not_to receive(:info).with(/Skipping/)
      expect(Chef::Log).not_to receive(:debug).with(/anymore/)
      Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      Object.send(:remove_const, "LwrpFoo")
    end

    it "should not skip loading a provider when there's a top level symbol of the same name" do
      Object.const_set("LwrpBuckPasser", Class.new)
      file = File.expand_path( "lwrp/providers/buck_passer.rb", CHEF_SPEC_DATA)
      expect(Chef::Log).not_to receive(:info).with(/Skipping/)
      expect(Chef::Log).not_to receive(:debug).with(/anymore/)
      Chef::Provider::LWRPBase.build_from_file("lwrp", file, nil)
      Object.send(:remove_const, "LwrpBuckPasser")
    end

    # @todo: we need a before block to manually remove_const all of the LWRPs that we
    #        load in these tests.  we're threading state through these tests in LWRPs that
    #        have already been loaded in prior tests, which probably renders some of them bogus

    it "should log if attempting to load resource of same name" do
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end

      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        expect(Chef::Log).to receive(:debug).with(/Skipping/)
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "should log if attempting to load provider of same name" do
      Dir[File.expand_path( "lwrp/providers/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, nil)
      end

      Dir[File.expand_path( "lwrp/providers/*", CHEF_SPEC_DATA)].each do |file|
        expect(Chef::Log).to receive(:debug).with(/Skipping/)
        Chef::Provider::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "keeps the old LRWP resource class in the list of resource subclasses" do
      # This was originally CHEF-3432 regression test. But with Chef 12 we are
      # not replacing the original classes anymore.
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
      first_lwr_foo_class = get_lwrp(:lwrp_foo)
      expect(Chef::Resource.resource_classes).to include(first_lwr_foo_class)
      Dir[File.expand_path( "lwrp/resources/*", CHEF_SPEC_DATA)].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
      expect(Chef::Resource.resource_classes).to include(first_lwr_foo_class)
    end

    it "does not attempt to remove classes from higher up namespaces [CHEF-4117]" do
      conflicting_lwrp_file = File.expand_path( "lwrp_const_scoping/resources/conflict.rb", CHEF_SPEC_DATA)
      # The test is that this should not raise an error:
      Chef::Resource::LWRPBase.build_from_file("lwrp_const_scoping", conflicting_lwrp_file, nil)
    end

  end

  context "When an LWRP resource in cookbook l-w-r-p is loaded" do
    before do
      @tmpdir = Dir.mktmpdir("lwrp_test")
      resource_path = File.join(@tmpdir, "foo.rb")
      IO.write(resource_path, "default_action :create")
      provider_path = File.join(@tmpdir, "foo.rb")
      IO.write(provider_path, <<-EOM)
        action :create do
          raise "hi"
        end
      EOM
    end

    it "Can find the resource at l_w_r_p_foo" do
    end
  end

  context "When an LWRP resource lwrp_foo is loaded" do
    before do
      @tmpdir = Dir.mktmpdir("lwrp_test")
      @lwrp_path = File.join(@tmpdir, "foo.rb")
      content = IO.read(File.expand_path("../../data/lwrp/resources/foo.rb", __FILE__))
      IO.write(@lwrp_path, content)
      Chef::Resource::LWRPBase.build_from_file("lwrp", @lwrp_path, nil)
      @original_resource = Chef::ResourceResolver.resolve(:lwrp_foo)
    end

    after do
      FileUtils.remove_entry @tmpdir
    end

    context "And the LWRP is asked to load again, this time with different code" do
      before do
        content = IO.read(File.expand_path("../../data/lwrp_override/resources/foo.rb", __FILE__))
        IO.write(@lwrp_path, content)
        Chef::Resource::LWRPBase.build_from_file("lwrp", @lwrp_path, nil)
      end

      it "Should load the old content, and not the new" do
        resource = Chef::ResourceResolver.resolve(:lwrp_foo)
        expect(resource).to eq @original_resource
        expect(resource.default_action).to eq([:pass_buck])
        expect(Chef.method_defined?(:method_created_by_override_lwrp_foo)).to be_falsey
      end
    end
  end

  describe "Lightweight Chef::Resource" do

    before do
      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, nil)
      end
    end

    it "should be resolvable with Chef::ResourceResolver.resolve(:lwrp_foo)" do
      expect(Chef::ResourceResolver.resolve(:lwrp_foo, node: Chef::Node.new)).to eq(get_lwrp(:lwrp_foo))
    end

    it "should set resource_name" do
      expect(get_lwrp(:lwrp_foo).new("blah").resource_name).to eql(:lwrp_foo)
    end

    it "should output the resource_name in .to_s" do
      expect(get_lwrp(:lwrp_foo).new("blah").to_s).to eq "lwrp_foo[blah]"
    end

    it "should have a class that outputs a reasonable string" do
      expect(get_lwrp(:lwrp_foo).to_s).to eq "Custom resource lwrp_foo from cookbook lwrp"
    end

    it "should add the specified actions to the allowed_actions array" do
      expect(get_lwrp(:lwrp_foo).new("blah").allowed_actions).to include(:pass_buck, :twiddle_thumbs)
    end

    it "should set the specified action as the default action" do
      expect(get_lwrp(:lwrp_foo).new("blah").action).to eq([:pass_buck])
    end

    it "should create a method for each attribute" do
      expect(get_lwrp(:lwrp_foo).new("blah").methods.map { |m| m.to_sym }).to include(:monkey)
    end

    it "should build attribute methods that respect validation rules" do
      expect { get_lwrp(:lwrp_foo).new("blah").monkey(42) }.to raise_error(ArgumentError)
    end

    it "should have access to the run context and node during class definition" do
      node = Chef::Node.new
      node.normal[:penguin_name] = "jackass"
      run_context = Chef::RunContext.new(node, Chef::CookbookCollection.new, @events)

      Dir[File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "lwrp", "resources_with_default_attributes", "*"))].each do |file|
        Chef::Resource::LWRPBase.build_from_file("lwrp", file, run_context)
      end

      cls = get_lwrp(:lwrp_nodeattr)
      expect(cls.node).to be_kind_of(Chef::Node)
      expect(cls.run_context).to be_kind_of(Chef::RunContext)
      expect(cls.node[:penguin_name]).to eql("jackass")
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

      context "lazy default values" do
        let(:klass) do
          Class.new(Chef::Resource::LWRPBase) do
            self.resource_name = :sample_resource
            attribute :food,  :default => lazy { "BACON!" * 3 }
            attribute :drink, :default => lazy { |r| "Drink after #{r.food}!" }
          end
        end

        let(:instance) { klass.new("kitchen") }

        it "evaluates the default value when requested" do
          expect(instance.food).to eq("BACON!BACON!BACON!")
        end

        it "evaluates yields self to the block" do
          expect(instance.drink).to eq("Drink after BACON!BACON!BACON!!")
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

      context "when the child does not define the methods" do
        let(:child) do
          Class.new(parent)
        end

        it "delegates #actions to the parent" do
          expect(child.actions).to eq([:nothing, :eat, :sleep])
        end

        it "delegates #default_action to the parent" do
          expect(child.default_action).to eq([:eat])
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
          expect(child.actions).to eq([:nothing, :dont_eat, :dont_sleep])
        end

        it "does not delegate #default_action to the parent" do
          expect(child.default_action).to eq([:dont_eat])
        end
      end

      context "when actions are already defined" do
        let(:child) do
          Class.new(parent) do
            actions :eat
            actions :sleep
            actions :drink
          end
        end

        def raise_if_deprecated!
          if Chef::VERSION.split(".").first.to_i > 12
            raise "This test should be removed and the associated code should be removed!"
          end
        end

        it "amends actions when they are already defined" do
          raise_if_deprecated!
          expect(child.actions).to eq([:nothing, :eat, :sleep, :drink])
        end
      end
    end

    describe "when actions is set to an array" do
      let(:resource_class) do
        Class.new(Chef::Resource::LWRPBase) do
          actions [ :eat, :sleep ]
        end
      end
      let(:resource) do
        resource_class.new("blah")
      end
      it "actions includes those actions" do
        expect(resource_class.actions).to eq [ :nothing, :eat, :sleep ]
      end
      it "allowed_actions includes those actions" do
        expect(resource_class.allowed_actions).to eq [ :nothing, :eat, :sleep ]
      end
      it "resource.allowed_actions includes those actions" do
        expect(resource.allowed_actions).to eq [ :nothing, :eat, :sleep ]
      end
    end

    describe "when allowed_actions is set to an array" do
      let(:resource_class) do
        Class.new(Chef::Resource::LWRPBase) do
          allowed_actions [ :eat, :sleep ]
        end
      end
      let(:resource) do
        resource_class.new("blah")
      end
      it "actions includes those actions" do
        expect(resource_class.actions).to eq [ :nothing, :eat, :sleep ]
      end
      it "allowed_actions includes those actions" do
        expect(resource_class.allowed_actions).to eq [ :nothing, :eat, :sleep ]
      end
      it "resource.allowed_actions includes those actions" do
        expect(resource.allowed_actions).to eq [ :nothing, :eat, :sleep ]
      end
    end
  end

  describe "Lightweight Chef::Provider" do

    let(:node) do
      Chef::Node.new.tap do |n|
        n.automatic[:platform] = :ubuntu
        n.automatic[:platform_version] = "8.10"
      end
    end

    let(:events) { Chef::EventDispatch::Dispatcher.new }

    let(:run_context) { Chef::RunContext.new(node, Chef::CookbookCollection.new({}), events) }

    let(:runner) { Chef::Runner.new(run_context) }

    let(:lwrp_cookbok_name) { "lwrp" }

    before do
      Chef::Provider::LWRPBase.class_eval { @loaded_lwrps = {} }
    end

    before(:each) do
      Dir[File.expand_path(File.expand_path("../../data/lwrp/resources/*", __FILE__))].each do |file|
        Chef::Resource::LWRPBase.build_from_file(lwrp_cookbok_name, file, run_context)
      end

      Dir[File.expand_path(File.expand_path("../../data/lwrp/providers/*", __FILE__))].each do |file|
        Chef::Provider::LWRPBase.build_from_file(lwrp_cookbok_name, file, run_context)
      end
    end

    it "should properly handle a new_resource reference" do
      resource = get_lwrp(:lwrp_foo).new("morpheus", run_context)
      resource.monkey("bob")
      resource.provider(get_lwrp_provider(:lwrp_monkey_name_printer))

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      provider.action_twiddle_thumbs
    end

    context "provider class created" do
      before do
        @old_treat_deprecation_warnings_as_errors = Chef::Config[:treat_deprecation_warnings_as_errors]
        Chef::Config[:treat_deprecation_warnings_as_errors] = false
      end

      after do
        Chef::Config[:treat_deprecation_warnings_as_errors] = @old_treat_deprecation_warnings_as_errors
      end

      it "should load the provider into a properly-named class" do
        expect(Chef::Provider.const_get("LwrpBuckPasser")).to be_kind_of(Class)
        expect(Chef::Provider::LwrpBuckPasser <= Chef::Provider::LWRPBase).to be_truthy
      end

      it "should create a method for each action" do
        expect(get_lwrp_provider(:lwrp_buck_passer).instance_methods).to include(:action_pass_buck)
        expect(get_lwrp_provider(:lwrp_thumb_twiddler).instance_methods).to include(:action_twiddle_thumbs)
      end

      it "sets itself as a provider for a resource of the same name" do
        found_providers = Chef::Platform::ProviderHandlerMap.instance.list(node, :lwrp_buck_passer)
        # we bypass the per-file loading to get the file to load each time,
        # which creates the LWRP class repeatedly. New things get prepended to
        # the list of providers.
        expect(found_providers.first).to eq(get_lwrp_provider(:lwrp_buck_passer))
      end

      context "with a cookbook with an underscore in the name" do

        let(:lwrp_cookbok_name) { "l_w_r_p" }

        it "sets itself as a provider for a resource of the same name" do
          found_providers = Chef::Platform::ProviderHandlerMap.instance.list(node, :l_w_r_p_buck_passer)
          expect(found_providers.size).to eq(1)
          expect(found_providers.last).to eq(get_lwrp_provider(:l_w_r_p_buck_passer))
        end
      end

      context "with a cookbook with a hypen in the name" do

        let(:lwrp_cookbok_name) { "l-w-r-p" }

        it "sets itself as a provider for a resource of the same name" do
          incorrect_providers = Chef::Platform::ProviderHandlerMap.instance.list(node, :'l-w-r-p_buck_passer')
          expect(incorrect_providers).to eq([])

          found_providers = Chef::Platform::ProviderHandlerMap.instance.list(node, :l_w_r_p_buck_passer)
          expect(found_providers.first).to eq(get_lwrp_provider(:l_w_r_p_buck_passer))
        end
      end
    end

    it "should insert resources embedded in the provider into the middle of the resource collection" do
      injector = get_lwrp(:lwrp_foo).new("morpheus", run_context)
      injector.action(:pass_buck)
      injector.provider(get_lwrp_provider(:lwrp_buck_passer))
      dummy = Chef::Resource::ZenMaster.new("keanu reeves", run_context)
      dummy.provider(Chef::Provider::Easy)
      run_context.resource_collection.insert(injector)
      run_context.resource_collection.insert(dummy)

      Chef::Runner.new(run_context).converge

      expect(run_context.resource_collection[0]).to eql(injector)
      expect(run_context.resource_collection[1].name).to eql("prepared_thumbs")
      expect(run_context.resource_collection[2].name).to eql("twiddled_thumbs")
      expect(run_context.resource_collection[3]).to eql(dummy)
    end

    it "should insert embedded resources from multiple providers, including from the last position, properly into the resource collection" do
      injector = get_lwrp(:lwrp_foo).new("morpheus", run_context)
      injector.action(:pass_buck)
      injector.provider(get_lwrp_provider(:lwrp_buck_passer))

      injector2 = get_lwrp(:lwrp_bar).new("tank", run_context)
      injector2.action(:pass_buck)
      injector2.provider(get_lwrp_provider(:lwrp_buck_passer_2))

      dummy = Chef::Resource::ZenMaster.new("keanu reeves", run_context)
      dummy.provider(Chef::Provider::Easy)

      run_context.resource_collection.insert(injector)
      run_context.resource_collection.insert(dummy)
      run_context.resource_collection.insert(injector2)

      Chef::Runner.new(run_context).converge

      expect(run_context.resource_collection[0]).to eql(injector)
      expect(run_context.resource_collection[1].name).to eql("prepared_thumbs")
      expect(run_context.resource_collection[2].name).to eql("twiddled_thumbs")
      expect(run_context.resource_collection[3]).to eql(dummy)
      expect(run_context.resource_collection[4]).to eql(injector2)
      expect(run_context.resource_collection[5].name).to eql("prepared_eyes")
      expect(run_context.resource_collection[6].name).to eql("dried_paint_watched")
    end

    it "should properly handle a new_resource reference" do
      resource = get_lwrp(:lwrp_foo).new("morpheus", run_context)
      resource.monkey("bob")
      resource.provider(get_lwrp_provider(:lwrp_monkey_name_printer))

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      provider.action_twiddle_thumbs

      expect(provider.monkey_name).to eq("my monkey's name is 'bob'")
    end

    it "should properly handle an embedded Resource accessing the enclosing Provider's scope" do
      resource = get_lwrp(:lwrp_foo).new("morpheus", run_context)
      resource.monkey("bob")
      resource.provider(get_lwrp_provider(:lwrp_embedded_resource_accesses_providers_scope))

      provider = Chef::Platform.provider_for_resource(resource, :twiddle_thumbs)
      #provider = @runner.build_provider(resource)
      provider.action_twiddle_thumbs

      expect(provider.enclosed_resource.monkey).to eq("bob, the monkey")
    end

    describe "when using inline compilation" do
      before do
        # Behavior in these examples depends on implementation of fixture provider.
        # See spec/data/lwrp/providers/inline_compiler

        # Side effect of lwrp_inline_compiler provider for testing notifications.
        $interior_ruby_block_2 = nil
        # resource type doesn't matter, so make an existing resource type work with provider.
        @resource = get_lwrp(:lwrp_foo).new("morpheus", run_context)
        @resource.allowed_actions << :test
        @resource.action(:test)
        @resource.provider(get_lwrp_provider(:lwrp_inline_compiler))
      end

      it "does not add interior resources to the exterior resource collection" do
        @resource.run_action(:test)
        expect(run_context.resource_collection).to be_empty
      end

      context "when interior resources are updated" do
        it "processes notifications within the LWRP provider's action" do
          @resource.run_action(:test)
          expect($interior_ruby_block_2).to eq("executed")
        end

        it "marks the parent resource updated" do
          @resource.run_action(:test)
          expect(@resource).to be_updated
          expect(@resource).to be_updated_by_last_action
        end
      end

      context "when interior resources are not updated" do
        it "does not mark the parent resource updated" do
          @resource.run_action(:no_updates)
          expect(@resource).not_to be_updated
          expect(@resource).not_to be_updated_by_last_action
        end
      end

    end
  end

  context "resource class created" do
    before(:context) do
      @tmpdir = Dir.mktmpdir("lwrp_test")
      resource_path = File.join(@tmpdir, "once.rb")
      IO.write(resource_path, "default_action :create")

      @old_treat_deprecation_warnings_as_errors = Chef::Config[:treat_deprecation_warnings_as_errors]
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
      Chef::Resource::LWRPBase.build_from_file("lwrp", resource_path, nil)
    end

    after(:context) do
      FileUtils.remove_entry @tmpdir
      Chef::Config[:treat_deprecation_warnings_as_errors] = @old_treat_deprecation_warnings_as_errors
    end

    it "should load the resource into a properly-named class" do
      expect(Chef::Resource::LwrpOnce).to be_kind_of(Class)
      expect(Chef::Resource::LwrpOnce <= Chef::Resource::LWRPBase).to be_truthy
    end

    it "get_lwrp(:lwrp_once).new is a Chef::Resource::LwrpOnce" do
      lwrp = get_lwrp(:lwrp_once).new("hi")
      expect(lwrp.kind_of?(Chef::Resource::LwrpOnce)).to be_truthy
      expect(lwrp.is_a?(Chef::Resource::LwrpOnce)).to be_truthy
      expect(get_lwrp(:lwrp_once) === lwrp).to be_truthy
      expect(Chef::Resource::LwrpOnce === lwrp).to be_truthy
    end

    it "Chef::Resource::LwrpOnce.new is a get_lwrp(:lwrp_once)" do
      lwrp = Chef::Resource::LwrpOnce.new("hi")
      expect(lwrp.kind_of?(get_lwrp(:lwrp_once))).to be_truthy
      expect(lwrp.is_a?(get_lwrp(:lwrp_once))).to be_truthy
      expect(get_lwrp(:lwrp_once) === lwrp).to be_truthy
      expect(Chef::Resource::LwrpOnce === lwrp).to be_truthy
    end

    it "works even if LwrpOnce exists in the top level" do
      module ::LwrpOnce
      end
      expect(Chef::Resource::LwrpOnce).not_to eq(::LwrpOnce)
    end

    it "allows monkey patching of the lwrp through Chef::Resource" do
      monkey = Module.new do
        def issue_3607
        end
      end
      Chef::Resource::LwrpOnce.send(:include, monkey)
      expect { get_lwrp(:lwrp_once).new("blah").issue_3607 }.not_to raise_error
    end

    context "with a subclass of get_lwrp(:lwrp_once)" do
      let(:subclass) do
        Class.new(get_lwrp(:lwrp_once))
      end

      it "subclass.new is a subclass" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(subclass)).to be_truthy
        expect(lwrp.is_a?(subclass)).to be_truthy
        expect(subclass === lwrp).to be_truthy
        expect(lwrp.class === subclass)
      end
      it "subclass.new is a Chef::Resource::LwrpOnce" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(Chef::Resource::LwrpOnce)).to be_truthy
        expect(lwrp.is_a?(Chef::Resource::LwrpOnce)).to be_truthy
        expect(Chef::Resource::LwrpOnce === lwrp).to be_truthy
        expect(lwrp.class === Chef::Resource::LwrpOnce)
      end
      it "subclass.new is a get_lwrp(:lwrp_once)" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(get_lwrp(:lwrp_once))).to be_truthy
        expect(lwrp.is_a?(get_lwrp(:lwrp_once))).to be_truthy
        expect(get_lwrp(:lwrp_once) === lwrp).to be_truthy
        expect(lwrp.class === get_lwrp(:lwrp_once))
      end
      it "Chef::Resource::LwrpOnce.new is *not* a subclass" do
        lwrp = Chef::Resource::LwrpOnce.new("hi")
        expect(lwrp.kind_of?(subclass)).to be_falsey
        expect(lwrp.is_a?(subclass)).to be_falsey
        expect(subclass === lwrp.class).to be_falsey
        expect(subclass === Chef::Resource::LwrpOnce).to be_falsey
      end
      it "get_lwrp(:lwrp_once).new is *not* a subclass" do
        lwrp = get_lwrp(:lwrp_once).new("hi")
        expect(lwrp.kind_of?(subclass)).to be_falsey
        expect(lwrp.is_a?(subclass)).to be_falsey
        expect(subclass === lwrp.class).to be_falsey
        expect(subclass === get_lwrp(:lwrp_once)).to be_falsey
      end
    end

    context "with a subclass of Chef::Resource::LwrpOnce" do
      let(:subclass) do
        Class.new(Chef::Resource::LwrpOnce)
      end

      it "subclass.new is a subclass" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(subclass)).to be_truthy
        expect(lwrp.is_a?(subclass)).to be_truthy
        expect(subclass === lwrp).to be_truthy
        expect(lwrp.class === subclass)
      end
      it "subclass.new is a Chef::Resource::LwrpOnce" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(Chef::Resource::LwrpOnce)).to be_truthy
        expect(lwrp.is_a?(Chef::Resource::LwrpOnce)).to be_truthy
        expect(Chef::Resource::LwrpOnce === lwrp).to be_truthy
        expect(lwrp.class === Chef::Resource::LwrpOnce)
      end
      it "subclass.new is a get_lwrp(:lwrp_once)" do
        lwrp = subclass.new("hi")
        expect(lwrp.kind_of?(get_lwrp(:lwrp_once))).to be_truthy
        expect(lwrp.is_a?(get_lwrp(:lwrp_once))).to be_truthy
        expect(get_lwrp(:lwrp_once) === lwrp).to be_truthy
        expect(lwrp.class === get_lwrp(:lwrp_once))
      end
      it "Chef::Resource::LwrpOnce.new is *not* a subclass" do
        lwrp = Chef::Resource::LwrpOnce.new("hi")
        expect(lwrp.kind_of?(subclass)).to be_falsey
        expect(lwrp.is_a?(subclass)).to be_falsey
        expect(subclass === lwrp.class).to be_falsey
        expect(subclass === Chef::Resource::LwrpOnce).to be_falsey
      end
      it "get_lwrp(:lwrp_once).new is *not* a subclass" do
        lwrp = get_lwrp(:lwrp_once).new("hi")
        expect(lwrp.kind_of?(subclass)).to be_falsey
        expect(lwrp.is_a?(subclass)).to be_falsey
        expect(subclass === lwrp.class).to be_falsey
        expect(subclass === get_lwrp(:lwrp_once)).to be_falsey
      end
    end
  end

  describe "extending the DSL mixin" do
    module MyAwesomeDSLExensionClass
      def my_awesome_dsl_extension(argument)
        argument
      end
    end

    class MyAwesomeResource < Chef::Resource::LWRPBase
      provides :my_awesome_resource
      resource_name :my_awesome_resource
      default_action :create
    end

    class MyAwesomeProvider < Chef::Provider::LWRPBase
      use_inline_resources

      provides :my_awesome_resource

      action :create do
        my_awesome_dsl_extension("foo")
      end
    end

    let(:recipe) {
      cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks"))
      cookbook_loader = Chef::CookbookLoader.new(cookbook_repo)
      cookbook_loader.load_cookbooks
      cookbook_collection = Chef::CookbookCollection.new(cookbook_loader)
      node = Chef::Node.new
      events = Chef::EventDispatch::Dispatcher.new
      run_context = Chef::RunContext.new(node, cookbook_collection, events)
      Chef::Recipe.new("hjk", "test", run_context)
    }

    it "lets you extend the recipe DSL" do
      expect(Chef::Recipe).to receive(:include).with(MyAwesomeDSLExensionClass)
      expect(Chef::Resource::ActionClass).to receive(:include).with(MyAwesomeDSLExensionClass)
      Chef::DSL::Recipe.send(:include, MyAwesomeDSLExensionClass)
    end

    it "lets you call your DSL from a recipe" do
      Chef::DSL::Recipe.send(:include, MyAwesomeDSLExensionClass)
      expect(recipe.my_awesome_dsl_extension("foo")).to eql("foo")
    end

    it "lets you call your DSL from a provider" do
      Chef::DSL::Recipe.send(:include, MyAwesomeDSLExensionClass)

      resource = MyAwesomeResource.new("name", run_context)
      run_context.resource_collection << resource

      runner = Chef::Runner.new(run_context)
      expect_any_instance_of(MyAwesomeProvider).to receive(:my_awesome_dsl_extension).and_call_original
      runner.converge
    end
  end

end
