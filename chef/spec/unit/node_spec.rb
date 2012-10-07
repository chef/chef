#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

describe Chef::Node do
  before(:each) do
    Chef::Config.node_path(File.expand_path(File.join(CHEF_SPEC_DATA, "nodes")))
    @node = Chef::Node.new()
  end

  it "creates a node and assigns it a name" do
    node = Chef::Node.build('solo-node')
    node.name.should == 'solo-node'
  end

  it "should validate the name of the node" do
    lambda{Chef::Node.build('solo node')}.should raise_error(Chef::Exceptions::ValidationFailed)
  end

  describe "when the node does not exist on the server" do
    before do
      response = OpenStruct.new(:code => '404')
      exception = Net::HTTPServerException.new("404 not found", response)
      Chef::Node.stub!(:load).and_raise(exception)
      @node.name("created-node")
    end

    it "creates a new node for find_or_create" do
      Chef::Node.stub!(:new).and_return(@node)
      @node.should_receive(:create).and_return(@node)
      node = Chef::Node.find_or_create("created-node")
      node.name.should == 'created-node'
      node.should equal(@node)
    end
  end

  describe "when the node exists on the server" do
    before do
      @node.name('existing-node')
      Chef::Node.stub!(:load).and_return(@node)
    end

    it "loads the node via the REST API for find_or_create" do
      Chef::Node.find_or_create('existing-node').should equal(@node)
    end
  end

  describe "run_state" do
    it "should have a template_cache hash" do
      @node.run_state[:template_cache].should be_a_kind_of(Hash)
    end

    it "should have a seen_recipes hash" do
      @node.run_state[:seen_recipes].should be_a_kind_of(Hash)
    end
  end

  describe "initialize" do
    it "should default to the '_default' chef_environment" do
      n = Chef::Node.new
      n.chef_environment.should == '_default'
    end
  end

  describe "name" do
    it "should allow you to set a name with name(something)" do
      lambda { @node.name("latte") }.should_not raise_error
    end

    it "should return the name with name()" do
      @node.name("latte")
      @node.name.should eql("latte")
    end

    it "should always have a string for name" do
      lambda { @node.name(Hash.new) }.should raise_error(ArgumentError)
    end

    it "cannot be blank" do
      lambda { @node.name("")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "should not accept name doesn't match /^[\-[:alnum:]_:.]+$/" do
      lambda { @node.name("space in it")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "chef_environment" do
    it "should set an environment with chef_environment(something)" do
      lambda { @node.chef_environment("latte") }.should_not raise_error
    end

    it "should return the chef_environment with chef_environment()" do
      @node.chef_environment("latte")
      @node.chef_environment.should == "latte"
    end

    it "should disallow non-strings" do
      lambda { @node.chef_environment(Hash.new) }.should raise_error(ArgumentError)
      lambda { @node.chef_environment(42) }.should raise_error(ArgumentError)
    end

    it "cannot be blank" do
      lambda { @node.chef_environment("")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "attributes" do
    it "should be loaded from the node's cookbooks" do
      @cookbook_repo = File.expand_path(File.join(File.dirname(__FILE__), "..", "data", "cookbooks"))
      cl = Chef::CookbookLoader.new(@cookbook_repo)
      cl.load_cookbooks
      @node.cookbook_collection = Chef::CookbookCollection.new(cl)
      @node.load_attributes
      @node.ldap_server.should eql("ops1prod")
      @node.ldap_basedn.should eql("dc=hjksolutions,dc=com")
      @node.ldap_replication_password.should eql("forsure")
      @node.smokey.should eql("robinson")
    end

    it "should have attributes" do
      @node.attribute.should be_a_kind_of(Hash)
    end

    it "should allow attributes to be accessed by name or symbol directly on node[]" do
      @node.default["locust"] = "something"
      @node[:locust].should eql("something")
      @node["locust"].should eql("something")
    end

    it "should return nil if it cannot find an attribute with node[]" do
      @node["secret"].should eql(nil)
    end

    it "does not allow you to set an attribute via node[]=" do
      lambda  { @node["secret"] = "shush" }.should raise_error(Chef::ImmutableAttributeModification)
    end

    it "should allow you to query whether an attribute exists with attribute?" do
      @node.default["locust"] = "something"
      @node.attribute?("locust").should eql(true)
      @node.attribute?("no dice").should eql(false)
    end

    it "should let you go deep with attribute?" do
      @node.set["battles"]["people"]["wonkey"] = true
      @node["battles"]["people"].attribute?("wonkey").should == true
      @node["battles"]["people"].attribute?("snozzberry").should == false
    end

    it "does not allow you to set an attribute via method_missing" do
      lambda { @node.sunshine = "is bright"}.should raise_error(Chef::ImmutableAttributeModification)
    end

    it "should allow you get get an attribute via method_missing" do
      @node.default.sunshine = "is bright"
      @node.sunshine.should eql("is bright")
    end

    describe "normal attributes" do
      it "should allow you to set an attribute with set, without pre-declaring a hash" do
        @node.set[:snoopy][:is_a_puppy] = true
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set an attribute with set_unless" do
        @node.set_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with set_unless if it already exists" do
        @node.set[:snoopy][:is_a_puppy] = true
        @node.set_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        @node.set.fuu.bahrr.baz = "qux"
        @node.fuu.bahrr.baz.should == "qux"
      end

    end

    describe "default attributes" do
      it "should be set with default, without pre-declaring a hash" do
        @node.default[:snoopy][:is_a_puppy] = true
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set with default_unless without pre-declaring a hash" do
        @node.default_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with default_unless if it already exists" do
        @node.default[:snoopy][:is_a_puppy] = true
        @node.default_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        @node.default.fuu.bahrr.baz = "qux"
        @node.fuu.bahrr.baz.should == "qux"
      end

    end

    describe "override attributes" do
      it "should be set with override, without pre-declaring a hash" do
        @node.override[:snoopy][:is_a_puppy] = true
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set with override_unless without pre-declaring a hash" do
        @node.override_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with override_unless if it already exists" do
        @node.override[:snoopy][:is_a_puppy] = true
        @node.override_unless[:snoopy][:is_a_puppy] = false
        @node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        @node.override.fuu.bahrr.baz = "qux"
        @node.fuu.bahrr.baz.should == "qux"
      end

    end

    it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
      lambda { @node.sunshine }.should raise_error(NoMethodError)
    end

    it "should allow you to iterate over attributes with each_attribute" do
      @node.default.sunshine = "is bright"
      @node.default.canada = "is a nice place"
      seen_attributes = Hash.new
      @node.each_attribute do |a,v|
        seen_attributes[a] = v
      end
      seen_attributes.should have_key("sunshine")
      seen_attributes.should have_key("canada")
      seen_attributes["sunshine"].should == "is bright"
      seen_attributes["canada"].should == "is a nice place"
    end
  end

  describe "consuming json" do

    before do
      @ohai_data = {:platform => 'foo', :platform_version => 'bar'}
    end

    it "consumes the run list portion of a collection of attributes and returns the remainder" do
      attrs = {"run_list" => [ "role[base]", "recipe[chef::server]" ], "foo" => "bar"}
      @node.consume_run_list(attrs).should == {"foo" => "bar"}
      @node.run_list.should == [ "role[base]", "recipe[chef::server]" ]
    end

    it "should overwrites the run list with the run list it consumes" do
      @node.consume_run_list "recipes" => [ "one", "two" ]
      @node.consume_run_list "recipes" => [ "three" ]
      @node.run_list.should == [ "three" ]
    end

    it "should not add duplicate recipes from the json attributes" do
      @node.run_list << "one"
      @node.consume_run_list "recipes" => [ "one", "two", "three" ]
      @node.run_list.should  == [ "one", "two", "three" ]
    end

    it "doesn't change the run list if no run_list is specified in the json" do
      @node.run_list << "role[database]"
      @node.consume_run_list "foo" => "bar"
      @node.run_list.should == ["role[database]"]
    end

    it "raises an exception if you provide both recipe and run_list attributes, since this is ambiguous" do
      lambda { @node.consume_run_list "recipes" => "stuff", "run_list" => "other_stuff" }.should raise_error(Chef::Exceptions::AmbiguousRunlistSpecification)
    end

    it "should add json attributes to the node" do
      @node.consume_external_attrs(@ohai_data, {"one" => "two", "three" => "four"})
      @node.one.should eql("two")
      @node.three.should eql("four")
    end

    it "should set the tags attribute to an empty array if it is not already defined" do
      @node.consume_external_attrs(@ohai_data, {})
      @node.tags.should eql([])
    end

    it "should not set the tags attribute to an empty array if it is already defined" do
      @node.normal[:tags] = [ "radiohead" ]
      @node.consume_external_attrs(@ohai_data, {})
      @node.tags.should eql([ "radiohead" ])
    end

    it "deep merges attributes instead of overwriting them" do
      @node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      @node.one.to_hash.should == {"two" => {"three" => "four"}}
      @node.consume_external_attrs(@ohai_data, "one" => {"abc" => "123"})
      @node.consume_external_attrs(@ohai_data, "one" => {"two" => {"foo" => "bar"}})
      @node.one.to_hash.should == {"two" => {"three" => "four", "foo" => "bar"}, "abc" => "123"}
    end

    it "gives attributes from JSON priority when deep merging" do
      @node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      @node.one.to_hash.should == {"two" => {"three" => "four"}}
      @node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "forty-two"}})
      @node.one.to_hash.should == {"two" => {"three" => "forty-two"}}
    end

  end

  describe "preparing for a chef client run" do
    before do
      @ohai_data = {:platform => 'foobuntu', :platform_version => '23.42'}
    end

    it "sets its platform according to platform detection" do
      @node.consume_external_attrs(@ohai_data, {})
      @node.automatic_attrs[:platform].should == 'foobuntu'
      @node.automatic_attrs[:platform_version].should == '23.42'
    end

    it "consumes the run list from provided json attributes" do
      @node.consume_external_attrs(@ohai_data, {"run_list" => ['recipe[unicorn]']})
      @node.run_list.should == ['recipe[unicorn]']
    end

    it "saves non-runlist json attrs for later" do
      expansion = Chef::RunList::RunListExpansion.new('_default', [])
      @node.run_list.stub!(:expand).and_return(expansion)
      @node.consume_external_attrs(@ohai_data, {"foo" => "bar"})
      @node.expand!
      @node.normal_attrs.should == {"foo" => "bar", "tags" => []}
    end

  end

  describe "when expanding its run list and merging attributes" do
    before do
      @expansion = Chef::RunList::RunListExpansion.new("_default", [])
      @node.run_list.stub!(:expand).and_return(@expansion)
    end

    it "sets the 'recipes' automatic attribute to the recipes in the expanded run_list" do
      @expansion.recipes << 'recipe[chef::client]' << 'recipe[nginx::default]'
      @node.expand!
      @node.automatic_attrs[:recipes].should == ['recipe[chef::client]', 'recipe[nginx::default]']
    end

    it "sets the 'roles' automatic attribute to the expanded role list" do
      @expansion.instance_variable_set(:@applied_roles, {'arf' => nil, 'countersnark' => nil})
      @node.expand!
      @node.automatic_attrs[:roles].sort.should == ['arf', 'countersnark']
    end

  end

  describe "when clearing computed state at the beginning of a run" do
    before do
      @node.default[:foo] = "default"
      @node.normal[:foo] = "normal"
      @node.override[:foo] = "override"
      @node.reset_defaults_and_overrides
    end

    it "removes default attributes" do
      @node.default.should be_empty
    end

    it "removes override attributes" do
      @node.override.should be_empty
    end

    it "leaves normal level attributes untouched" do
      @node[:foo].should == "normal"
    end

  end

  describe "Code cleanup TODO" do
    it "has tests for merging environment attrs" do
      pending
    end
  end

  # TODO: timh, cw: 2010-5-19: Node.recipe? deprecated. See node.rb
  # describe "recipes" do
  #   it "should have a RunList of recipes that should be applied" do
  #     @node.recipes.should be_a_kind_of(Chef::RunList)
  #   end
  #
  #   it "should allow you to query whether or not it has a recipe applied with recipe?" do
  #     @node.recipes << "sunrise"
  #     @node.recipe?("sunrise").should eql(true)
  #     @node.recipe?("not at home").should eql(false)
  #   end
  #
  #   it "should allow you to query whether or not a recipe has been applied, even if it was included" do
  #     @node.run_state[:seen_recipes]["snakes"] = true
  #     @node.recipe?("snakes").should eql(true)
  #   end
  #
  #   it "should return false if a recipe has not been seen" do
  #     @node.recipe?("snakes").should eql(false)
  #   end
  #
  #   it "should allow you to set recipes with arguments" do
  #     @node.recipes "one", "two"
  #     @node.recipe?("one").should eql(true)
  #     @node.recipe?("two").should eql(true)
  #   end
  # end

  describe "roles" do
    it "should allow you to query whether or not it has a recipe applied with role?" do
      @node.run_list << "role[sunrise]"
      @node.role?("sunrise").should eql(true)
      @node.role?("not at home").should eql(false)
    end

    it "should allow you to set roles with arguments" do
      @node.run_list << "role[one]"
      @node.run_list << "role[two]"
      @node.role?("one").should eql(true)
      @node.role?("two").should eql(true)
    end
  end

  describe "run_list" do
    it "should have a Chef::RunList of recipes and roles that should be applied" do
      @node.run_list.should be_a_kind_of(Chef::RunList)
    end

    it "should allow you to query the run list with arguments" do
      @node.run_list "recipe[baz]"
      @node.run_list?("recipe[baz]").should eql(true)
    end

    it "should allow you to set the run list with arguments" do
      @node.run_list "recipe[baz]", "role[foo]"
      @node.run_list?("recipe[baz]").should eql(true)
      @node.run_list?("role[foo]").should eql(true)
    end
  end

  describe "from file" do
    it "should load a node from a ruby file" do
      @node.from_file(File.expand_path(File.join(CHEF_SPEC_DATA, "nodes", "test.rb")))
      @node.name.should eql("test.example.com-short")
      @node.sunshine.should eql("in")
      @node.something.should eql("else")
      @node.run_list.should == ["operations-master", "operations-monitoring"]
    end

    it "should raise an exception if the file cannot be found or read" do
      lambda { @node.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
    end
  end

  describe "find_file" do
    it "should load a node from a file by fqdn" do
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com"
      @node.chef_environment.should == "dev"
    end

    it "should load a node from a file by hostname" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com-short"
    end

    it "should load a node from the default file" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.rb")).and_return(false)
      @node.find_file("test.example.com")
      @node.name.should == "test.example.com-default"
    end

    it "should raise an ArgumentError if it cannot find any node file at all" do
      File.stub!(:exists?).and_return(true)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.example.com.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "test.rb")).and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:node_path], "default.rb")).and_return(false)
      lambda { @node.find_file("test.example.com") }.should raise_error(ArgumentError)
    end
  end

  describe "update_from!" do
    before(:each) do
      @node.name("orig")
      @node.chef_environment("dev")
      @node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      @node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      @node.normal_attrs = { "one" => { "two" => "seven" } }
      @node.run_list << "role[marxist]"
      @node.run_list << "role[leninist]"
      @node.run_list << "recipe[stalinist]"

      @example = Chef::Node.new()
      @example.name("newname")
      @example.chef_environment("prod")
      @example.default_attrs = { "alpha" => { "bravo" => "charlie", "delta" => "echo" } }
      @example.override_attrs = { "alpha" => { "bravo" => "foxtrot", "delta" => "golf" } }
      @example.normal_attrs = { "alpha" => { "bravo" => "hotel" } }
      @example.run_list << "role[comedy]"
      @example.run_list << "role[drama]"
      @example.run_list << "recipe[mystery]"
    end

    it "allows update of everything except name" do
      @node.update_from!(@example)
      @node.name.should == "orig"
      @node.chef_environment.should == @example.chef_environment
      @node.default_attrs.should == @example.default_attrs
      @node.override_attrs.should == @example.override_attrs
      @node.normal_attrs.should == @example.normal_attrs
      @node.run_list.should == @example.run_list
    end

    it "should not update the name of the node" do
      @node.should_not_receive(:name).with(@example.name)
      @node.update_from!(@example)
    end
  end

  describe "to_hash" do
    it "should serialize itself as a hash" do
      @node.chef_environment("dev")
      @node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      @node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      @node.normal_attrs = { "one" => { "two" => "seven" } }
      @node.run_list << "role[marxist]"
      @node.run_list << "role[leninist]"
      @node.run_list << "recipe[stalinist]"
      h = @node.to_hash
      h["one"]["two"].should == "three"
      h["one"]["four"].should == "six"
      h["one"]["eight"].should == "nine"
      h["role"].should be_include("marxist")
      h["role"].should be_include("leninist")
      h["run_list"].should be_include("role[marxist]")
      h["run_list"].should be_include("role[leninist]")
      h["run_list"].should be_include("recipe[stalinist]")
      h["chef_environment"].should == "dev"
    end
  end

  describe "json" do
    it "should serialize itself as json", :json => true do
      @node.find_file("test.example.com")
      json = Chef::JSONCompat.to_json(@node)
      json.should =~ /json_class/
      json.should =~ /name/
      json.should =~ /chef_environment/
      json.should =~ /normal/
      json.should =~ /default/
      json.should =~ /override/
      json.should =~ /run_list/
    end

    it 'should serialze valid json with a run list', :json => true do
      #This test came about because activesupport mucks with Chef json serialization
      #Test should pass with and without Activesupport
      @node.run_list << {"type" => "role", "name" => 'Cthulu'}
      @node.run_list << {"type" => "role", "name" => 'Hastur'}
      json = Chef::JSONCompat.to_json(@node)
      json.should =~ /\"run_list\":\[\"role\[Cthulu\]\",\"role\[Hastur\]\"\]/
    end

    it "should deserialize itself from json", :json => true do
      @node.find_file("test.example.com")
      json = Chef::JSONCompat.to_json(@node)
      serialized_node = Chef::JSONCompat.from_json(json)
      serialized_node.should be_a_kind_of(Chef::Node)
      serialized_node.name.should eql(@node.name)
      serialized_node.chef_environment.should eql(@node.chef_environment)
      @node.each_attribute do |k,v|
        serialized_node[k].should eql(v)
      end
      serialized_node.run_list.should == @node.run_list
    end
  end

  describe "to_s" do
    it "should turn into a string like node[name]" do
      @node.name("airplane")
      @node.to_s.should eql("node[airplane]")
    end
  end

  describe "api model" do
    before(:each) do
      @rest = mock("Chef::REST")
      Chef::REST.stub!(:new).and_return(@rest)
      @query = mock("Chef::Search::Query")
      Chef::Search::Query.stub!(:new).and_return(@query)
    end

    describe "list" do
      describe "inflated" do
        it "should return a hash of node names and objects" do
          n1 = mock("Chef::Node", :name => "one")
          @query.should_receive(:search).with(:node).and_yield(n1)
          r = Chef::Node.list(true)
          r["one"].should == n1
        end
      end

      it "should return a hash of node names and urls" do
        @rest.should_receive(:get_rest).and_return({ "one" => "http://foo" })
        r = Chef::Node.list
        r["one"].should == "http://foo"
      end
    end

    describe "load" do
      it "should load a node by name" do
        @rest.should_receive(:get_rest).with("nodes/monkey").and_return("foo")
        Chef::Node.load("monkey").should == "foo"
      end
    end

    describe "destroy" do
      it "should destroy a node" do
        @rest.should_receive(:delete_rest).with("nodes/monkey").and_return("foo")
        @node.name("monkey")
        @node.destroy
      end
    end

    describe "save" do
      it "should update a node if it already exists" do
        @node.name("monkey")
        @rest.should_receive(:put_rest).with("nodes/monkey", @node).and_return("foo")
        @node.save
      end

      it "should not try and create if it can update" do
        @node.name("monkey")
        @rest.should_receive(:put_rest).with("nodes/monkey", @node).and_return("foo")
        @rest.should_not_receive(:post_rest)
        @node.save
      end

      it "should create if it cannot update" do
        @node.name("monkey")
        exception = mock("404 error", :code => "404")
        @rest.should_receive(:put_rest).and_raise(Net::HTTPServerException.new("foo", exception))
        @rest.should_receive(:post_rest).with("nodes", @node)
        @node.save
      end

      describe "when whyrun mode is enabled" do
        before do
          Chef::Config[:why_run] = true
        end
        after do
          Chef::Config[:why_run] = false
        end
        it "should not save" do
          @node.name("monkey")
          @rest.should_not_receive(:put_rest)
          @rest.should_not_receive(:post_rest)
          @node.save
        end
      end
    end
  end

  describe "acting as a CouchDB-backed model" do
    before(:each) do
      @couchdb = Chef::CouchDB.new
      @mock_couch = mock('couch mock')
    end

    describe "list" do
      before(:each) do
        @mock_couch.stub!(:list).and_return(
          { "rows" => [ { "value" => "a", "key" => "avenue" } ] }
        )
        Chef::CouchDB.stub!(:new).and_return(@mock_couch)
      end

      it "should retrieve a list of nodes from CouchDB" do
        Chef::Node.cdb_list.should eql(["avenue"])
      end

      it "should return just the ids if inflate is false" do
        Chef::Node.cdb_list(false).should eql(["avenue"])
      end

      it "should return the full objects if inflate is true" do
        Chef::Node.cdb_list(true).should eql(["a"])
      end
    end

    describe "when loading a given node" do
      it "should load a node from couchdb by name" do
        @couchdb.should_receive(:load).with("node", "coffee").and_return(true)
        Chef::CouchDB.stub!(:new).and_return(@couchdb)
        Chef::Node.cdb_load("coffee")
      end
    end

    describe "when destroying a Node" do
      it "should delete this node from couchdb" do
        @couchdb.should_receive(:delete).with("node", "bob", 1).and_return(true)
        Chef::CouchDB.stub!(:new).and_return(@couchdb)
        node = Chef::Node.new
        node.name "bob"
        node.couchdb_rev = 1
        node.cdb_destroy
      end
    end

    describe "when saving a Node" do
      before(:each) do
        @couchdb.stub!(:store).and_return({ "rev" => 33 })
        Chef::CouchDB.stub!(:new).and_return(@couchdb)
        @node = Chef::Node.new
        @node.name "bob"
        @node.couchdb_rev = 1
      end

      it "should save the node to couchdb" do
        @couchdb.should_receive(:store).with("node", "bob", @node).and_return({ "rev" => 33 })
        @node.cdb_save
      end

      it "should store the new couchdb_rev" do
        @node.cdb_save
        @node.couchdb_rev.should eql(33)
      end
    end

    describe "create_design_document" do
      it "should create our design document" do
        @couchdb.should_receive(:create_design_document).with("nodes", Chef::Node::DESIGN_DOCUMENT)
        Chef::CouchDB.stub!(:new).and_return(@couchdb)
        Chef::Node.create_design_document
      end
    end

  end

end
