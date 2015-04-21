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
require 'chef/platform/resource_priority_map'

describe Chef::Recipe do

  let(:cookbook_repo) { File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks")) }

  let(:cookbook_loader) do
    loader = Chef::CookbookLoader.new(cookbook_repo)
    loader.load_cookbooks
    loader
  end

  let(:cookbook_collection) { Chef::CookbookCollection.new(cookbook_loader) }

  let(:node) do
    Chef::Node.new.tap {|n| n.normal[:tags] = [] }
  end

  let(:events) do
    Chef::EventDispatch::Dispatcher.new
  end

  let(:run_context) do
    Chef::RunContext.new(node, cookbook_collection, events)
  end

  let(:recipe) do
    Chef::Recipe.new("hjk", "test", run_context)
  end

  describe "method_missing" do
    describe "resources" do
      it "should load a two word (zen_master) resource" do
        expect do
          recipe.zen_master "monkey" do
            peace true
          end
        end.not_to raise_error
      end

      it "should load a one word (cat) resource" do
        expect do
          recipe.cat "loulou" do
            pretty_kitty true
          end
        end.not_to raise_error
      end

      it "should load a four word (one_two_three_four) resource" do
        expect do
          recipe.one_two_three_four "numbers" do
            i_can_count true
          end
        end.not_to raise_error
      end

      it "should throw an error if you access a resource that we can't find" do
        expect { recipe.not_home("not_home_resource") }.to raise_error(NameError)
      end

      it "should require a name argument" do
        expect {
          recipe.cat
        }.to raise_error(ArgumentError, "You must supply a name when declaring a cat resource")
      end

      it "should allow regular errors (not NameErrors) to pass unchanged" do
        expect {
          recipe.cat("felix") { raise ArgumentError, "You Suck" }
        }.to raise_error(ArgumentError)
      end

      it "should add our zen_master to the collection" do
        recipe.zen_master "monkey" do
          peace true
        end
        expect(run_context.resource_collection.lookup("zen_master[monkey]").name).to eql("monkey")
      end

      it "should add our zen masters to the collection in the order they appear" do
        %w{monkey dog cat}.each do |name|
          recipe.zen_master name do
            peace true
          end
        end

        expect(run_context.resource_collection.map{|r| r.name}).to eql(["monkey", "dog", "cat"])
      end

      it "should return the new resource after creating it" do
        res = recipe.zen_master "makoto" do
          peace true
        end
        expect(res.resource_name).to eql(:zen_master)
        expect(res.name).to eql("makoto")
      end

      describe "should locate platform mapped resources" do

        it "locate resource for particular platform" do
          ShaunTheSheep = Class.new(Chef::Resource)
          ShaunTheSheep.provides :laughter, :on_platforms => ["television"]
          node.automatic[:platform] = "television"
          node.automatic[:platform_version] = "123"
          res = recipe.laughter "timmy"
          expect(res.name).to eql("timmy")
          res.kind_of?(ShaunTheSheep)
        end

        it "locate a resource for all platforms" do
          YourMom = Class.new(Chef::Resource)
          YourMom.provides :love_and_caring
          res = recipe.love_and_caring "mommy"
          expect(res.name).to eql("mommy")
          res.kind_of?(YourMom)
        end

        describe "when there is more than one resource that resolves on a node" do
          before do
            node.automatic[:platform] = "nbc_sports"
            Sounders = Class.new(Chef::Resource)
            Sounders.provides :football, platform: "nbc_sports"
            TottenhamHotspur = Class.new(Chef::Resource)
            TottenhamHotspur.provides :football, platform: "nbc_sports"
          end

          after do
            Object.send(:remove_const, :Sounders)
            Object.send(:remove_const, :TottenhamHotspur)
          end

          it "warns if resolution of the two resources is ambiguous" do
            expect(Chef::Log).to receive(:warn).at_least(:once).with(/Ambiguous resource precedence/)
            res1 = recipe.football "club world cup"
            expect(res1.name).to eql("club world cup")
            # the class of res1 is not defined.
          end

          it "selects one if it is given priority" do
            expect(Chef::Log).not_to receive(:warn)
            Chef::Platform::ResourcePriorityMap.instance.send(:priority, :football, TottenhamHotspur, platform: "nbc_sports")
            res1 = recipe.football "club world cup"
            expect(res1.name).to eql("club world cup")
            expect(res1).to be_a_kind_of(TottenhamHotspur)
          end

          it "selects the other one if it is given priority" do
            expect(Chef::Log).not_to receive(:warn)
            Chef::Platform::ResourcePriorityMap.instance.send(:priority, :football, Sounders, platform: "nbc_sports")
            res1 = recipe.football "club world cup"
            expect(res1.name).to eql("club world cup")
            expect(res1).to be_a_kind_of(Sounders)
          end
        end

      end
    end

    describe "creating resources via build_resource" do
      let(:zm_resource) do
        recipe.build_resource(:zen_master, "klopp") do
          something "bvb"
        end
      end

      it "applies attributes from the block to the resource" do
        expect(zm_resource.something).to eq("bvb")
      end

      it "sets contextual attributes on the resource" do
        expect(zm_resource.recipe_name).to eq("test")
        expect(zm_resource.cookbook_name).to eq("hjk")
        expect(zm_resource.source_line).to include(__FILE__)
        expect(zm_resource.declared_type).to eq(:zen_master)
      end

      it "does not add the resource to the resource collection" do
        zm_resource # force let binding evaluation
        expect { run_context.resource_collection.resources(:zen_master => "klopp") }.to raise_error(Chef::Exceptions::ResourceNotFound)
      end
    end

    describe "when cloning resources" do
      def expect_warning
        expect(Chef::Log).to receive(:warn).with(/3694/)
        expect(Chef::Log).to receive(:warn).with(/Previous/)
        expect(Chef::Log).to receive(:warn).with(/Current/)
      end

      it "should emit a 3694 warning when attributes change" do
        recipe.zen_master "klopp" do
          something "bvb"
        end
        expect_warning
        recipe.zen_master "klopp" do
          something "vbv"
        end
      end

      it "should emit a 3694 warning when attributes change" do
        recipe.zen_master "klopp" do
          something "bvb"
        end
        expect_warning
        recipe.zen_master "klopp" do
          something "bvb"
          peace true
        end
      end

      it "should emit a 3694 warning when attributes change" do
        recipe.zen_master "klopp" do
          something "bvb"
          peace true
        end
        expect_warning
        recipe.zen_master "klopp" do
          something "bvb"
        end
      end

      it "should emit a 3694 warning for non-trivial attributes (unfortunately)" do
        recipe.zen_master "klopp" do
          something "bvb"
        end
        expect_warning
        recipe.zen_master "klopp" do
          something "bvb"
        end
      end

      it "should not emit a 3694 warning for completely trivial resource cloning" do
        recipe.zen_master "klopp"
        expect(Chef::Log).to_not receive(:warn)
        recipe.zen_master "klopp"
      end

      it "should not emit a 3694 warning when attributes do not change and the first action is :nothing" do
        recipe.zen_master "klopp" do
          action :nothing
        end
        expect(Chef::Log).to_not receive(:warn)
        recipe.zen_master "klopp" do
          action :score
        end
      end

      it "should not emit a 3694 warning when attributes do not change and the second action is :nothing" do
        recipe.zen_master "klopp" do
          action :score
        end
        expect(Chef::Log).to_not receive(:warn)
        recipe.zen_master "klopp" do
          action :nothing
        end
      end

      it "validating resources via build_resource" do
        expect {recipe.build_resource(:remote_file, "klopp") do
          source Chef::DelayedEvaluator.new {"http://chef.io"}
        end}.to_not raise_error
      end

    end



    describe "creating resources via declare_resource" do
      let(:zm_resource) do
        recipe.declare_resource(:zen_master, "klopp") do
          something "bvb"
        end
      end

      it "applies attributes from the block to the resource" do
        expect(zm_resource.something).to eq("bvb")
      end

      it "sets contextual attributes on the resource" do
        expect(zm_resource.recipe_name).to eq("test")
        expect(zm_resource.cookbook_name).to eq("hjk")
        expect(zm_resource.source_line).to include(__FILE__)
      end

      it "adds the resource to the resource collection" do
        zm_resource # force let binding evaluation
        expect(run_context.resource_collection.resources(:zen_master => "klopp")).to eq(zm_resource)
      end
    end

    describe "creating a resource with short name" do
      # zen_follower resource has this:
      # provides :follower, :on_platforms => ["zen"]
      before do
        node.automatic_attrs[:platform] = "zen"
      end

      let(:resource_follower) do
        recipe.declare_resource(:follower, "srst") do
          master "none"
        end
      end

      it "defines the resource using the declaration name with short name" do
        resource_follower
        expect(run_context.resource_collection.lookup("follower[srst]")).not_to be_nil
      end
    end

    describe "creating a resource with a long name" do
      let(:resource_zn_follower) do
        recipe.declare_resource(:zen_follower, "srst") do
          master "none"
        end
      end


      it "defines the resource using the declaration name with long name" do
        resource_zn_follower
        expect(run_context.resource_collection.lookup("zen_follower[srst]")).not_to be_nil
      end
    end

    describe "when attempting to create a resource of an invalid type" do

      it "gives a sane error message when using method_missing" do
        expect do
          recipe.no_such_resource("foo")
        end.to raise_error(NoMethodError, %q[No resource or method named `no_such_resource' for `Chef::Recipe "test"'])
      end

      it "gives a sane error message when using method_missing 'bare'" do
        expect do
          recipe.instance_eval do
            # Giving an argument will change this from NameError to NoMethodError
            no_such_resource
          end
        end.to raise_error(NameError, %q[No resource, method, or local variable named `no_such_resource' for `Chef::Recipe "test"'])
      end

      it "gives a sane error message when using build_resource" do
        expect { recipe.build_resource(:no_such_resource, "foo") }.to raise_error(Chef::Exceptions::NoSuchResourceType)
      end

      it "gives a sane error message when using declare_resource" do
        expect { recipe.declare_resource(:no_such_resource, "bar") }.to raise_error(Chef::Exceptions::NoSuchResourceType)
      end

    end

    describe "when creating a resource that contains an error in the attributes block" do

      it "does not obfuscate the error source" do
        expect do
          recipe.zen_master("klopp") do
            this_method_doesnt_exist
          end
        end.to raise_error(NoMethodError, "undefined method `this_method_doesnt_exist' for Chef::Resource::ZenMaster")

      end

    end

    describe "resource cloning" do

      let(:second_recipe) do
        Chef::Recipe.new("second_cb", "second_recipe", run_context)
      end

      let(:original_resource) do
        recipe.zen_master("klopp") do
          something "bvb09"
          action :score
        end
      end

      let(:duplicated_resource) do
        original_resource
        second_recipe.zen_master("klopp") do
          # attrs should be cloned
        end
      end

      it "copies attributes from the first resource" do
        expect(duplicated_resource.something).to eq("bvb09")
      end

      it "does not copy the action from the first resource" do
        expect(original_resource.action).to eq([:score])
        expect(duplicated_resource.action).to eq(:nothing)
      end

      it "does not copy the source location of the first resource" do
        # sanity check source location:
        expect(original_resource.source_line).to include(__FILE__)
        expect(duplicated_resource.source_line).to include(__FILE__)
        # actual test:
        expect(original_resource.source_line).not_to eq(duplicated_resource.source_line)
      end

      it "sets the cookbook name on the cloned resource to that resource's cookbook" do
        expect(duplicated_resource.cookbook_name).to eq("second_cb")
      end

      it "sets the recipe name on the cloned resource to that resoure's recipe" do
        expect(duplicated_resource.recipe_name).to eq("second_recipe")
      end

    end

    describe "resource definitions" do
      it "should execute defined resources" do
        crow_define = Chef::ResourceDefinition.new
        crow_define.define :crow, :peace => false, :something => true do
          zen_master "lao tzu" do
            peace params[:peace]
            something params[:something]
          end
        end
        run_context.definitions[:crow] = crow_define
        recipe.crow "mine" do
          peace true
        end
        expect(run_context.resource_collection.resources(:zen_master => "lao tzu").name).to eql("lao tzu")
        expect(run_context.resource_collection.resources(:zen_master => "lao tzu").something).to eql(true)
      end

      it "should set the node on defined resources" do
        crow_define = Chef::ResourceDefinition.new
        crow_define.define :crow, :peace => false, :something => true do
          zen_master "lao tzu" do
            peace params[:peace]
            something params[:something]
          end
        end
        run_context.definitions[:crow] = crow_define
        node.normal[:foo] = false
        recipe.crow "mine" do
          something node[:foo]
        end
        expect(recipe.resources(:zen_master => "lao tzu").something).to eql(false)
      end

      it "should return the last statement in the definition as the retval" do
        crow_define = Chef::ResourceDefinition.new
        crow_define.define :crow, :peace => false, :something => true do
          "the return val"
        end
        run_context.definitions[:crow] = crow_define
        crow_block = recipe.crow "mine" do
          peace true
        end
        expect(crow_block).to eql("the return val")
      end
    end

  end

  describe "instance_eval" do
    it "should handle an instance_eval properly" do
      code = <<-CODE
  zen_master "gnome" do
    peace = true
  end
  CODE
      expect { recipe.instance_eval(code) }.not_to raise_error
      expect(recipe.resources(:zen_master => "gnome").name).to eql("gnome")
    end
  end

  describe "handle exec calls" do
    it "should raise ResourceNotFound error if exec is used" do
      code = <<-CODE
      exec 'do_not_try_to_exec'
      CODE
      expect { recipe.instance_eval(code) }.to raise_error(Chef::Exceptions::ResourceNotFound)
    end
  end

  describe "from_file" do
    it "should load a resource from a ruby file" do
      recipe.from_file(File.join(CHEF_SPEC_DATA, "recipes", "test.rb"))
      res = recipe.resources(:file => "/etc/nsswitch.conf")
      expect(res.name).to eql("/etc/nsswitch.conf")
      expect(res.action).to eql([:create])
      expect(res.owner).to eql("root")
      expect(res.group).to eql("root")
      expect(res.mode).to eql(0644)
    end

    it "should raise an exception if the file cannot be found or read" do
      expect { recipe.from_file("/tmp/monkeydiving") }.to raise_error(IOError)
    end
  end

  describe "include_recipe" do
    it "should evaluate another recipe with include_recipe" do
      expect(node).to receive(:loaded_recipe).with(:openldap, "gigantor")
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap::gigantor"
      res = run_context.resource_collection.resources(:cat => "blanket")
      expect(res.name).to eql("blanket")
      expect(res.pretty_kitty).to eql(false)
    end

    it "should load the default recipe for a cookbook if include_recipe is called without a ::" do
      expect(node).to receive(:loaded_recipe).with(:openldap, "default")
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap"
      res = run_context.resource_collection.resources(:cat => "blanket")
      expect(res.name).to eql("blanket")
      expect(res.pretty_kitty).to eql(true)
    end

    it "should store that it has seen a recipe in the run_context" do
      expect(node).to receive(:loaded_recipe).with(:openldap, "default")
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap"
      expect(run_context.loaded_recipe?("openldap")).to be_truthy
    end

    it "should not include the same recipe twice" do
      expect(node).to receive(:loaded_recipe).with(:openldap, "default").exactly(:once)
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      expect(cookbook_collection[:openldap]).to receive(:load_recipe).with("default", run_context)
      recipe.include_recipe "openldap"
      expect(cookbook_collection[:openldap]).not_to receive(:load_recipe).with("default", run_context)
      recipe.include_recipe "openldap"
    end

    it "will load a recipe out of the current cookbook when include_recipe is called with a leading ::" do
      openldap_recipe = Chef::Recipe.new("openldap", "test", run_context)
      expect(node).to receive(:loaded_recipe).with(:openldap, "default").exactly(:once)
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      expect(cookbook_collection[:openldap]).to receive(:load_recipe).with("default", run_context)
      openldap_recipe.include_recipe "::default"
    end

    it "will not include the same recipe twice when using leading :: syntax" do
      openldap_recipe = Chef::Recipe.new("openldap", "test", run_context)
      expect(node).to receive(:loaded_recipe).with(:openldap, "default").exactly(:once)
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      expect(cookbook_collection[:openldap]).to receive(:load_recipe).with("default", run_context)
      openldap_recipe.include_recipe "::default"
      expect(cookbook_collection[:openldap]).not_to receive(:load_recipe).with("default", run_context)
      openldap_recipe.include_recipe "openldap::default"
    end

    it "will not include the same recipe twice when using leading :: syntax (reversed order)" do
      openldap_recipe = Chef::Recipe.new("openldap", "test", run_context)
      expect(node).to receive(:loaded_recipe).with(:openldap, "default").exactly(:once)
      allow(run_context).to receive(:unreachable_cookbook?).with(:openldap).and_return(false)
      expect(cookbook_collection[:openldap]).to receive(:load_recipe).with("default", run_context)
      openldap_recipe.include_recipe "openldap::default"
      expect(cookbook_collection[:openldap]).not_to receive(:load_recipe).with("default", run_context)
      openldap_recipe.include_recipe "::default"
    end
  end

  describe "tags" do
    describe "with the default node object" do
      let(:node) { Chef::Node.new }

      it "should return false for any tags" do
        expect(recipe.tagged?("foo")).to be(false)
      end
    end

    it "should set tags via tag" do
      recipe.tag "foo"
      expect(node[:tags]).to include("foo")
    end

    it "should set multiple tags via tag" do
      recipe.tag "foo", "bar"
      expect(node[:tags]).to include("foo")
      expect(node[:tags]).to include("bar")
    end

    it "should not set the same tag twice via tag" do
      recipe.tag "foo"
      recipe.tag "foo"
      expect(node[:tags]).to eql([ "foo" ])
    end

    it "should return the current list of tags from tag with no arguments" do
      recipe.tag "foo"
      expect(recipe.tag).to eql([ "foo" ])
    end

    it "should return true from tagged? if node is tagged" do
      recipe.tag "foo"
      expect(recipe.tagged?("foo")).to be(true)
    end

    it "should return false from tagged? if node is not tagged" do
      expect(recipe.tagged?("foo")).to be(false)
    end

    it "should return false from tagged? if node is not tagged" do
      expect(recipe.tagged?("foo")).to be(false)
    end

    it "should remove a tag from the tag list via untag" do
      recipe.tag "foo"
      recipe.untag "foo"
      expect(node[:tags]).to eql([])
    end

    it "should remove multiple tags from the tag list via untag" do
      recipe.tag "foo", "bar"
      recipe.untag "bar", "foo"
      expect(node[:tags]).to eql([])
    end
  end

  describe "included DSL" do
    it "should include features from Chef::DSL::Audit" do
      expect(recipe.singleton_class.included_modules).to include(Chef::DSL::Audit)
      expect(recipe.respond_to?(:control_group)).to be true
    end

    it "should respond to :ps_credential from Chef::DSL::Powershell" do
      expect(recipe.respond_to?(:ps_credential)).to be true
    end
  end
end
