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
  before(:each) do
    @cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks"))
    cl = Chef::CookbookLoader.new(@cookbook_repo)
    cl.load_cookbooks
    @cookbook_collection = Chef::CookbookCollection.new(cl)
    @node = Chef::Node.new
    @node.normal[:tags] = Array.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, @cookbook_collection, @events)
    @recipe = Chef::Recipe.new("hjk", "test", @run_context)

    # Shell/ext.rb is on the run path, and it defines
    # Chef::Recipe#resources to call pp, which we don't want when
    # we're running tests.
    @recipe.stub!(:pp)
  end

  describe "method_missing" do
    describe "resources" do
      it "should load a two word (zen_master) resource" do
        lambda do
          @recipe.zen_master "monkey" do
            peace true
          end
        end.should_not raise_error(ArgumentError)
      end

      it "should load a one word (cat) resource" do
        lambda do
          @recipe.cat "loulou" do
            pretty_kitty true
          end
        end.should_not raise_error(ArgumentError)
      end

      it "should load a four word (one_two_three_four) resource" do
        lambda do
          @recipe.one_two_three_four "numbers" do
            i_can_count true
          end
        end.should_not raise_error(ArgumentError)
      end

      it "should throw an error if you access a resource that we can't find" do
        lambda { @recipe.not_home("not_home_resource") }.should raise_error(NameError)
      end

      it "should require a name argument" do
        lambda {
          @recipe.cat
        }.should raise_error(ArgumentError, "You must supply a name when declaring a cat resource")
      end

      it "should allow regular errors (not NameErrors) to pass unchanged" do
        lambda {
          @recipe.cat("felix") { raise ArgumentError, "You Suck" }
        }.should raise_error(ArgumentError)
      end

      it "should add our zen_master to the collection" do
        @recipe.zen_master "monkey" do
          peace true
        end
        @run_context.resource_collection.lookup("zen_master[monkey]").name.should eql("monkey")
      end

      it "should add our zen masters to the collection in the order they appear" do
        %w{monkey dog cat}.each do |name|
          @recipe.zen_master name do
            peace true
          end
        end

        @run_context.resource_collection.map{|r| r.name}.should eql(["monkey", "dog", "cat"])
      end

      it "should return the new resource after creating it" do
        res = @recipe.zen_master "makoto" do
          peace true
        end
        res.resource_name.should eql(:zen_master)
        res.name.should eql("makoto")
      end

      describe "should locate platform mapped resources" do

        it "locate resource for particular platform" do
          Object.const_set('ShaunTheSheep', Class.new(Chef::Resource){ provides :laughter, :on_platforms => ["television"] })
          @node.automatic[:platform] = "television"
          @node.automatic[:platform_version] = "123"
          res = @recipe.laughter "timmy"
          res.name.should eql("timmy")
          res.kind_of?(ShaunTheSheep)
        end

        it "locate a resource for all platforms" do
          Object.const_set("YourMom", Class.new(Chef::Resource){ provides :love_and_caring })
          res = @recipe.love_and_caring "mommy"
          res.name.should eql("mommy")
          res.kind_of?(YourMom)
        end

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
        @run_context.definitions[:crow] = crow_define
        @recipe.crow "mine" do
          peace true
        end
        @run_context.resource_collection.resources(:zen_master => "lao tzu").name.should eql("lao tzu")
        @run_context.resource_collection.resources(:zen_master => "lao tzu").something.should eql(true)
      end

      it "should set the node on defined resources" do
        crow_define = Chef::ResourceDefinition.new
        crow_define.define :crow, :peace => false, :something => true do
          zen_master "lao tzu" do
            peace params[:peace]
            something params[:something]
          end
        end
        @run_context.definitions[:crow] = crow_define
        @node.normal[:foo] = false
        @recipe.crow "mine" do
          something node[:foo]
        end
        @recipe.resources(:zen_master => "lao tzu").something.should eql(false)
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
      lambda { @recipe.instance_eval(code) }.should_not raise_error
      @recipe.resources(:zen_master => "gnome").name.should eql("gnome")
    end
  end

  describe "from_file" do
    it "should load a resource from a ruby file" do
      @recipe.from_file(File.join(CHEF_SPEC_DATA, "recipes", "test.rb"))
      res = @recipe.resources(:file => "/etc/nsswitch.conf")
      res.name.should eql("/etc/nsswitch.conf")
      res.action.should eql([:create])
      res.owner.should eql("root")
      res.group.should eql("root")
      res.mode.should eql(0644)
    end

    it "should raise an exception if the file cannot be found or read" do
      lambda { @recipe.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
    end
  end

  describe "include_recipe" do
    it "should evaluate another recipe with include_recipe" do
      @run_context.include_recipe "openldap::gigantor"
      res = @run_context.resource_collection.resources(:cat => "blanket")
      res.name.should eql("blanket")
      res.pretty_kitty.should eql(false)
    end

    it "should load the default recipe for a cookbook if include_recipe is called without a ::" do
      @run_context.include_recipe "openldap"
      res = @run_context.resource_collection.resources(:cat => "blanket")
      res.name.should eql("blanket")
      res.pretty_kitty.should eql(true)
    end

    it "should store that it has seen a recipe in the run_context" do
      @run_context.include_recipe "openldap"
      @run_context.loaded_recipe?("openldap").should be_true
    end

    it "should not include the same recipe twice" do
      @cookbook_collection[:openldap].should_receive(:load_recipe).with("default", @run_context)
      @recipe.include_recipe "openldap"
      @cookbook_collection[:openldap].should_not_receive(:load_recipe).with("default", @run_context)
      @recipe.include_recipe "openldap"
    end
  end

  describe "tags" do
    it "should set tags via tag" do
      @recipe.tag "foo"
      @node[:tags].should include("foo")
    end

    it "should set multiple tags via tag" do
      @recipe.tag "foo", "bar"
      @node[:tags].should include("foo")
      @node[:tags].should include("bar")
    end

    it "should not set the same tag twice via tag" do
      @recipe.tag "foo"
      @recipe.tag "foo"
      @node[:tags].should eql([ "foo" ])
    end

    it "should return the current list of tags from tag with no arguments" do
      @recipe.tag "foo"
      @recipe.tag.should eql([ "foo" ])
    end

    it "should return true from tagged? if node is tagged" do
      @recipe.tag "foo"
      @recipe.tagged?("foo").should be(true)
    end

    it "should return false from tagged? if node is not tagged" do
      @recipe.tagged?("foo").should be(false)
    end

    it "should return false from tagged? if node is not tagged" do
      @recipe.tagged?("foo").should be(false)
    end

    it "should remove a tag from the tag list via untag" do
      @recipe.tag "foo"
      @recipe.untag "foo"
      @node[:tags].should eql([])
    end

    it "should remove multiple tags from the tag list via untag" do
      @recipe.tag "foo", "bar"
      @recipe.untag "bar", "foo"
      @node[:tags].should eql([])
    end
  end
end
