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
        lambda do
          recipe.zen_master "monkey" do
            peace true
          end
        end.should_not raise_error
      end

      it "should load a one word (cat) resource" do
        lambda do
          recipe.cat "loulou" do
            pretty_kitty true
          end
        end.should_not raise_error
      end

      it "should load a four word (one_two_three_four) resource" do
        lambda do
          recipe.one_two_three_four "numbers" do
            i_can_count true
          end
        end.should_not raise_error
      end

      it "should throw an error if you access a resource that we can't find" do
        lambda { recipe.not_home("not_home_resource") }.should raise_error(NameError)
      end

      it "should require a name argument" do
        lambda {
          recipe.cat
        }.should raise_error(ArgumentError, "You must supply a name when declaring a cat resource")
      end

      it "should allow regular errors (not NameErrors) to pass unchanged" do
        lambda {
          recipe.cat("felix") { raise ArgumentError, "You Suck" }
        }.should raise_error(ArgumentError)
      end

      it "should add our zen_master to the collection" do
        recipe.zen_master "monkey" do
          peace true
        end
        run_context.resource_collection.lookup("zen_master[monkey]").name.should eql("monkey")
      end

      it "should add our zen masters to the collection in the order they appear" do
        %w{monkey dog cat}.each do |name|
          recipe.zen_master name do
            peace true
          end
        end

        run_context.resource_collection.map{|r| r.name}.should eql(["monkey", "dog", "cat"])
      end

      it "should return the new resource after creating it" do
        res = recipe.zen_master "makoto" do
          peace true
        end
        res.resource_name.should eql(:zen_master)
        res.name.should eql("makoto")
      end

      describe "should locate platform mapped resources" do

        it "locate resource for particular platform" do
          ShaunTheSheep = Class.new(Chef::Resource)
          ShaunTheSheep.provides :laughter, :on_platforms => ["television"]
          node.automatic[:platform] = "television"
          node.automatic[:platform_version] = "123"
          res = recipe.laughter "timmy"
          res.name.should eql("timmy")
          res.kind_of?(ShaunTheSheep)
        end

        it "locate a resource for all platforms" do
          YourMom = Class.new(Chef::Resource)
          YourMom.provides :love_and_caring
          res = recipe.love_and_caring "mommy"
          res.name.should eql("mommy")
          res.kind_of?(YourMom)
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
        zm_resource.something.should == "bvb"
      end

      it "sets contextual attributes on the resource" do
        zm_resource.recipe_name.should == "test"
        zm_resource.cookbook_name.should == "hjk"
        zm_resource.source_line.should include(__FILE__)
        zm_resource.declared_type.should == :zen_master
      end

      it "does not add the resource to the resource collection" do
        zm_resource # force let binding evaluation
        expect { run_context.resource_collection.resources(:zen_master => "klopp") }.to raise_error(Chef::Exceptions::ResourceNotFound)
      end

    end

    describe "creating resources via declare_resource" do
      let(:zm_resource) do
        recipe.declare_resource(:zen_master, "klopp") do
          something "bvb"
        end
      end

      it "applies attributes from the block to the resource" do
        zm_resource.something.should == "bvb"
      end

      it "sets contextual attributes on the resource" do
        zm_resource.recipe_name.should == "test"
        zm_resource.cookbook_name.should == "hjk"
        zm_resource.source_line.should include(__FILE__)
      end

      it "adds the resource to the resource collection" do
        zm_resource # force let binding evaluation
        run_context.resource_collection.resources(:zen_master => "klopp").should == zm_resource
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
        run_context.resource_collection.lookup("follower[srst]").should_not be_nil
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
        run_context.resource_collection.lookup("zen_follower[srst]").should_not be_nil
      end
    end

    describe "when attempting to create a resource of an invalid type" do

      it "gives a sane error message when using method_missing" do
        lambda do
          recipe.no_such_resource("foo")
        end.should raise_error(NoMethodError, %q[No resource or method named `no_such_resource' for `Chef::Recipe "test"'])
      end

      it "gives a sane error message when using method_missing 'bare'" do
        lambda do
          recipe.instance_eval do
            # Giving an argument will change this from NameError to NoMethodError
            no_such_resource
          end
        end.should raise_error(NameError, %q[No resource, method, or local variable named `no_such_resource' for `Chef::Recipe "test"'])
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
        lambda do
          recipe.zen_master("klopp") do
            this_method_doesnt_exist
          end
        end.should raise_error(NoMethodError, "undefined method `this_method_doesnt_exist' for Chef::Resource::ZenMaster")

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
        duplicated_resource.something.should == "bvb09"
      end

      it "does not copy the action from the first resource" do
        original_resource.action.should == [:score]
        duplicated_resource.action.should == :nothing
      end

      it "does not copy the source location of the first resource" do
        # sanity check source location:
        original_resource.source_line.should include(__FILE__)
        duplicated_resource.source_line.should include(__FILE__)
        # actual test:
        original_resource.source_line.should_not == duplicated_resource.source_line
      end

      it "sets the cookbook name on the cloned resource to that resource's cookbook" do
        duplicated_resource.cookbook_name.should == "second_cb"
      end

      it "sets the recipe name on the cloned resource to that resoure's recipe" do
        duplicated_resource.recipe_name.should == "second_recipe"
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
        run_context.resource_collection.resources(:zen_master => "lao tzu").name.should eql("lao tzu")
        run_context.resource_collection.resources(:zen_master => "lao tzu").something.should eql(true)
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
        recipe.resources(:zen_master => "lao tzu").something.should eql(false)
      end

      it "should return the last statement in the definition as the retval" do
        crow_define = Chef::ResourceDefinition.new
        crow_define.define :crow, :peace => false, :something => true do
          "the return val"
        end
        run_context.definitions[:crow] = crow_define
        recipe.crow "mine" do
          peace true
        end.should eql("the return val")
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
      lambda { recipe.instance_eval(code) }.should_not raise_error
      recipe.resources(:zen_master => "gnome").name.should eql("gnome")
    end
  end

  describe "handle exec calls" do
    it "should raise ResourceNotFound error if exec is used" do
      code = <<-CODE
      exec 'do_not_try_to_exec'
      CODE
      lambda { recipe.instance_eval(code) }.should raise_error(Chef::Exceptions::ResourceNotFound)
    end
  end

  describe "from_file" do
    it "should load a resource from a ruby file" do
      recipe.from_file(File.join(CHEF_SPEC_DATA, "recipes", "test.rb"))
      res = recipe.resources(:file => "/etc/nsswitch.conf")
      res.name.should eql("/etc/nsswitch.conf")
      res.action.should eql([:create])
      res.owner.should eql("root")
      res.group.should eql("root")
      res.mode.should eql(0644)
    end

    it "should raise an exception if the file cannot be found or read" do
      lambda { recipe.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
    end
  end

  describe "include_recipe" do
    it "should evaluate another recipe with include_recipe" do
      node.should_receive(:loaded_recipe).with(:openldap, "gigantor")
      run_context.stub(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap::gigantor"
      res = run_context.resource_collection.resources(:cat => "blanket")
      res.name.should eql("blanket")
      res.pretty_kitty.should eql(false)
    end

    it "should load the default recipe for a cookbook if include_recipe is called without a ::" do
      node.should_receive(:loaded_recipe).with(:openldap, "default")
      run_context.stub(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap"
      res = run_context.resource_collection.resources(:cat => "blanket")
      res.name.should eql("blanket")
      res.pretty_kitty.should eql(true)
    end

    it "should store that it has seen a recipe in the run_context" do
      node.should_receive(:loaded_recipe).with(:openldap, "default")
      run_context.stub(:unreachable_cookbook?).with(:openldap).and_return(false)
      run_context.include_recipe "openldap"
      run_context.loaded_recipe?("openldap").should be_true
    end

    it "should not include the same recipe twice" do
      node.should_receive(:loaded_recipe).with(:openldap, "default").exactly(:once)
      run_context.stub(:unreachable_cookbook?).with(:openldap).and_return(false)
      cookbook_collection[:openldap].should_receive(:load_recipe).with("default", run_context)
      recipe.include_recipe "openldap"
      cookbook_collection[:openldap].should_not_receive(:load_recipe).with("default", run_context)
      recipe.include_recipe "openldap"
    end
  end

  describe "tags" do
    describe "with the default node object" do
      let(:node) { Chef::Node.new }

      it "should return false for any tags" do
        recipe.tagged?("foo").should be(false)
      end
    end

    it "should set tags via tag" do
      recipe.tag "foo"
      node[:tags].should include("foo")
    end

    it "should set multiple tags via tag" do
      recipe.tag "foo", "bar"
      node[:tags].should include("foo")
      node[:tags].should include("bar")
    end

    it "should not set the same tag twice via tag" do
      recipe.tag "foo"
      recipe.tag "foo"
      node[:tags].should eql([ "foo" ])
    end

    it "should return the current list of tags from tag with no arguments" do
      recipe.tag "foo"
      recipe.tag.should eql([ "foo" ])
    end

    it "should return true from tagged? if node is tagged" do
      recipe.tag "foo"
      recipe.tagged?("foo").should be(true)
    end

    it "should return false from tagged? if node is not tagged" do
      recipe.tagged?("foo").should be(false)
    end

    it "should return false from tagged? if node is not tagged" do
      recipe.tagged?("foo").should be(false)
    end

    it "should remove a tag from the tag list via untag" do
      recipe.tag "foo"
      recipe.untag "foo"
      node[:tags].should eql([])
    end

    it "should remove multiple tags from the tag list via untag" do
      recipe.tag "foo", "bar"
      recipe.untag "bar", "foo"
      node[:tags].should eql([])
    end
  end
end
