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

  let(:node) { Chef::Node.new() }
  let(:platform_introspector) { node }

  it_behaves_like "a platform introspector"

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
      node.name("created-node")
    end

    it "creates a new node for find_or_create" do
      Chef::Node.stub!(:new).and_return(node)
      node.should_receive(:create).and_return(node)
      node = Chef::Node.find_or_create("created-node")
      node.name.should == 'created-node'
      node.should equal(node)
    end
  end

  describe "when the node exists on the server" do
    before do
      node.name('existing-node')
      Chef::Node.stub!(:load).and_return(node)
    end

    it "loads the node via the REST API for find_or_create" do
      Chef::Node.find_or_create('existing-node').should equal(node)
    end
  end

  describe "run_state" do
    it "is an empty hash" do
      node.run_state.should respond_to(:keys)
      node.run_state.should be_empty
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
      lambda { node.name("latte") }.should_not raise_error
    end

    it "should return the name with name()" do
      node.name("latte")
      node.name.should eql("latte")
    end

    it "should always have a string for name" do
      lambda { node.name(Hash.new) }.should raise_error(ArgumentError)
    end

    it "cannot be blank" do
      lambda { node.name("")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end

    it "should not accept name doesn't match /^[\-[:alnum:]_:.]+$/" do
      lambda { node.name("space in it")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "chef_environment" do
    it "should set an environment with chef_environment(something)" do
      lambda { node.chef_environment("latte") }.should_not raise_error
    end

    it "should return the chef_environment with chef_environment()" do
      node.chef_environment("latte")
      node.chef_environment.should == "latte"
    end

    it "should disallow non-strings" do
      lambda { node.chef_environment(Hash.new) }.should raise_error(ArgumentError)
      lambda { node.chef_environment(42) }.should raise_error(ArgumentError)
    end

    it "cannot be blank" do
      lambda { node.chef_environment("")}.should raise_error(Chef::Exceptions::ValidationFailed)
    end
  end

  describe "attributes" do
    it "should have attributes" do
      node.attribute.should be_a_kind_of(Hash)
    end

    it "should allow attributes to be accessed by name or symbol directly on node[]" do
      node.default["locust"] = "something"
      node[:locust].should eql("something")
      node["locust"].should eql("something")
    end

    it "should return nil if it cannot find an attribute with node[]" do
      node["secret"].should eql(nil)
    end

    it "does not allow you to set an attribute via node[]=" do
      lambda  { node["secret"] = "shush" }.should raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should allow you to query whether an attribute exists with attribute?" do
      node.default["locust"] = "something"
      node.attribute?("locust").should eql(true)
      node.attribute?("no dice").should eql(false)
    end

    it "should let you go deep with attribute?" do
      node.set["battles"]["people"]["wonkey"] = true
      node["battles"]["people"].attribute?("wonkey").should == true
      node["battles"]["people"].attribute?("snozzberry").should == false
    end

    it "does not allow you to set an attribute via method_missing" do
      lambda { node.sunshine = "is bright"}.should raise_error(Chef::Exceptions::ImmutableAttributeModification)
    end

    it "should allow you get get an attribute via method_missing" do
      node.default.sunshine = "is bright"
      node.sunshine.should eql("is bright")
    end

    describe "normal attributes" do
      it "should allow you to set an attribute with set, without pre-declaring a hash" do
        node.set[:snoopy][:is_a_puppy] = true
        node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set an attribute with set_unless" do
        node.set_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with set_unless if it already exists" do
        node.set[:snoopy][:is_a_puppy] = true
        node.set_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        node.set.fuu.bahrr.baz = "qux"
        node.fuu.bahrr.baz.should == "qux"
      end

    end

    describe "default attributes" do
      it "should be set with default, without pre-declaring a hash" do
        node.default[:snoopy][:is_a_puppy] = true
        node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set with default_unless without pre-declaring a hash" do
        node.default_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with default_unless if it already exists" do
        node.default[:snoopy][:is_a_puppy] = true
        node.default_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        node.default.fuu.bahrr.baz = "qux"
        node.fuu.bahrr.baz.should == "qux"
      end

      it "accesses force defaults via default!" do
        node.default![:foo] = "wet bar"
        node.default[:foo] = "bar"
        node[:foo].should == "wet bar"
      end

    end

    describe "override attributes" do
      it "should be set with override, without pre-declaring a hash" do
        node.override[:snoopy][:is_a_puppy] = true
        node[:snoopy][:is_a_puppy].should == true
      end

      it "should allow you to set with override_unless without pre-declaring a hash" do
        node.override_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == false
      end

      it "should not allow you to set an attribute with override_unless if it already exists" do
        node.override[:snoopy][:is_a_puppy] = true
        node.override_unless[:snoopy][:is_a_puppy] = false
        node[:snoopy][:is_a_puppy].should == true
      end

      it "auto-vivifies attributes created via method syntax" do
        node.override.fuu.bahrr.baz = "qux"
        node.fuu.bahrr.baz.should == "qux"
      end

      it "sets force_overrides via override!" do
        node.override![:foo] = "wet bar"
        node.override[:foo] = "bar"
        node[:foo].should == "wet bar"
      end

    end

    it "should raise an ArgumentError if you ask for an attribute that doesn't exist via method_missing" do
      lambda { node.sunshine }.should raise_error(NoMethodError)
    end

    it "should allow you to iterate over attributes with each_attribute" do
      node.default.sunshine = "is bright"
      node.default.canada = "is a nice place"
      seen_attributes = Hash.new
      node.each_attribute do |a,v|
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
      node.consume_run_list(attrs).should == {"foo" => "bar"}
      node.run_list.should == [ "role[base]", "recipe[chef::server]" ]
    end

    it "should overwrites the run list with the run list it consumes" do
      node.consume_run_list "recipes" => [ "one", "two" ]
      node.consume_run_list "recipes" => [ "three" ]
      node.run_list.should == [ "three" ]
    end

    it "should not add duplicate recipes from the json attributes" do
      node.run_list << "one"
      node.consume_run_list "recipes" => [ "one", "two", "three" ]
      node.run_list.should  == [ "one", "two", "three" ]
    end

    it "doesn't change the run list if no run_list is specified in the json" do
      node.run_list << "role[database]"
      node.consume_run_list "foo" => "bar"
      node.run_list.should == ["role[database]"]
    end

    it "raises an exception if you provide both recipe and run_list attributes, since this is ambiguous" do
      lambda { node.consume_run_list "recipes" => "stuff", "run_list" => "other_stuff" }.should raise_error(Chef::Exceptions::AmbiguousRunlistSpecification)
    end

    it "should add json attributes to the node" do
      node.consume_external_attrs(@ohai_data, {"one" => "two", "three" => "four"})
      node.one.should eql("two")
      node.three.should eql("four")
    end

    it "should set the tags attribute to an empty array if it is not already defined" do
      node.consume_external_attrs(@ohai_data, {})
      node.tags.should eql([])
    end

    it "should not set the tags attribute to an empty array if it is already defined" do
      node.normal[:tags] = [ "radiohead" ]
      node.consume_external_attrs(@ohai_data, {})
      node.tags.should eql([ "radiohead" ])
    end

    it "deep merges attributes instead of overwriting them" do
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      node.one.to_hash.should == {"two" => {"three" => "four"}}
      node.consume_external_attrs(@ohai_data, "one" => {"abc" => "123"})
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"foo" => "bar"}})
      node.one.to_hash.should == {"two" => {"three" => "four", "foo" => "bar"}, "abc" => "123"}
    end

    it "gives attributes from JSON priority when deep merging" do
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "four"}})
      node.one.to_hash.should == {"two" => {"three" => "four"}}
      node.consume_external_attrs(@ohai_data, "one" => {"two" => {"three" => "forty-two"}})
      node.one.to_hash.should == {"two" => {"three" => "forty-two"}}
    end

  end

  describe "preparing for a chef client run" do
    before do
      @ohai_data = {:platform => 'foobuntu', :platform_version => '23.42'}
    end

    it "sets its platform according to platform detection" do
      node.consume_external_attrs(@ohai_data, {})
      node.automatic_attrs[:platform].should == 'foobuntu'
      node.automatic_attrs[:platform_version].should == '23.42'
    end

    it "consumes the run list from provided json attributes" do
      node.consume_external_attrs(@ohai_data, {"run_list" => ['recipe[unicorn]']})
      node.run_list.should == ['recipe[unicorn]']
    end

    it "saves non-runlist json attrs for later" do
      expansion = Chef::RunList::RunListExpansion.new('_default', [])
      node.run_list.stub!(:expand).and_return(expansion)
      node.consume_external_attrs(@ohai_data, {"foo" => "bar"})
      node.expand!
      node.normal_attrs.should == {"foo" => "bar", "tags" => []}
    end

  end

  describe "when expanding its run list and merging attributes" do
    before do
      @environment = Chef::Environment.new.tap do |e|
        e.name('rspec_env')
        e.default_attributes("env default key" => "env default value")
        e.override_attributes("env override key" => "env override value")
      end
      Chef::Environment.should_receive(:load).with("rspec_env").and_return(@environment)
      @expansion = Chef::RunList::RunListExpansion.new("rspec_env", [])
      node.chef_environment("rspec_env")
      node.run_list.stub!(:expand).and_return(@expansion)
    end

    it "sets the 'recipes' automatic attribute to the recipes in the expanded run_list" do
      @expansion.recipes << 'recipe[chef::client]' << 'recipe[nginx::default]'
      node.expand!
      node.automatic_attrs[:recipes].should == ['recipe[chef::client]', 'recipe[nginx::default]']
    end

    it "sets the 'roles' automatic attribute to the expanded role list" do
      @expansion.instance_variable_set(:@applied_roles, {'arf' => nil, 'countersnark' => nil})
      node.expand!
      node.automatic_attrs[:roles].sort.should == ['arf', 'countersnark']
    end

    it "applies default attributes from the environment as environment defaults" do
      node.expand!
      node.attributes.env_default["env default key"].should == "env default value"
    end

    it "applies override attributes from the environment as env overrides" do
      node.expand!
      node.attributes.env_override["env override key"].should == "env override value"
    end

    it "applies default attributes from roles as role defaults" do
      @expansion.default_attrs["role default key"] = "role default value"
      node.expand!
      node.attributes.role_default["role default key"].should == "role default value"
    end

    it "applies override attributes from roles as role overrides" do
      @expansion.override_attrs["role override key"] = "role override value"
      node.expand!
      node.attributes.role_override["role override key"].should == "role override value"
    end
  end

  describe "when querying for recipes in the run list" do
    context "when a recipe is in the top level run list" do
      before do
        node.run_list << "recipe[nginx::module]"
      end

      it "finds the recipe" do
        node.recipe?("nginx::module").should be_true
      end

      it "does not find a recipe not in the run list" do
        node.recipe?("nginx::other_module").should be_false
      end
    end
    context "when a recipe is in the expanded run list only" do
      before do
        node.run_list << "role[base]"
        node.automatic_attrs[:recipes] = [ "nginx::module" ]
      end

      it "finds a recipe in the expanded run list" do
        node.recipe?("nginx::module").should be_true
      end

      it "does not find a recipe that's not in the run list" do
        node.recipe?("nginx::other_module").should be_false
      end
    end
  end

  describe "when clearing computed state at the beginning of a run" do
    before do
      node.default[:foo] = "default"
      node.normal[:foo] = "normal"
      node.override[:foo] = "override"
      node.reset_defaults_and_overrides
    end

    it "removes default attributes" do
      node.default.should be_empty
    end

    it "removes override attributes" do
      node.override.should be_empty
    end

    it "leaves normal level attributes untouched" do
      node[:foo].should == "normal"
    end

  end

  describe "when merging environment attributes" do
    before do
      node.chef_environment = "rspec"
      @expansion = Chef::RunList::RunListExpansion.new("rspec", [])
      @expansion.default_attrs.replace({:default => "from role", :d_role => "role only"})
      @expansion.override_attrs.replace({:override => "from role", :o_role => "role only"})


      @environment = Chef::Environment.new
      @environment.default_attributes = {:default => "from env", :d_env => "env only" }
      @environment.override_attributes = {:override => "from env", :o_env => "env only"}
      Chef::Environment.stub!(:load).and_return(@environment)
      node.apply_expansion_attributes(@expansion)
    end

    it "does not nuke role-only default attrs" do
      node[:d_role].should == "role only"
    end

    it "does not nuke role-only override attrs" do
      node[:o_role].should == "role only"
    end

    it "does not nuke env-only default attrs" do
      node[:o_env].should == "env only"
    end

    it "does not nuke role-only override attrs" do
      node[:o_env].should == "env only"
    end

    it "gives role defaults precedence over env defaults" do
      node[:default].should == "from role"
    end

    it "gives env overrides precedence over role overrides" do
      node[:override].should == "from env"
    end
  end

  describe "when evaluating attributes files" do
    before do
      @cookbook_repo = File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
      @cookbook_loader = Chef::CookbookLoader.new(@cookbook_repo)
      @cookbook_loader.load_cookbooks

      @cookbook_collection = Chef::CookbookCollection.new(@cookbook_loader.cookbooks_by_name)

      @events = Chef::EventDispatch::Dispatcher.new
      @run_context = Chef::RunContext.new(node, @cookbook_collection, @events)

      node.include_attribute("openldap::default")
      node.include_attribute("openldap::smokey")
    end

    it "sets attributes from the files" do
      node.ldap_server.should eql("ops1prod")
      node.ldap_basedn.should eql("dc=hjksolutions,dc=com")
      node.ldap_replication_password.should eql("forsure")
      node.smokey.should eql("robinson")
    end

    it "gives a sensible error when attempting to load a missing attributes file" do
      lambda { node.include_attribute("nope-this::doesnt-exist") }.should raise_error(Chef::Exceptions::CookbookNotFound)
    end
  end

  describe "roles" do
    it "should allow you to query whether or not it has a recipe applied with role?" do
      node.run_list << "role[sunrise]"
      node.role?("sunrise").should eql(true)
      node.role?("not at home").should eql(false)
    end

    it "should allow you to set roles with arguments" do
      node.run_list << "role[one]"
      node.run_list << "role[two]"
      node.role?("one").should eql(true)
      node.role?("two").should eql(true)
    end
  end

  describe "run_list" do
    it "should have a Chef::RunList of recipes and roles that should be applied" do
      node.run_list.should be_a_kind_of(Chef::RunList)
    end

    it "should allow you to query the run list with arguments" do
      node.run_list "recipe[baz]"
      node.run_list?("recipe[baz]").should eql(true)
    end

    it "should allow you to set the run list with arguments" do
      node.run_list "recipe[baz]", "role[foo]"
      node.run_list?("recipe[baz]").should eql(true)
      node.run_list?("role[foo]").should eql(true)
    end
  end

  describe "from file" do
    it "should load a node from a ruby file" do
      node.from_file(File.expand_path(File.join(CHEF_SPEC_DATA, "nodes", "test.rb")))
      node.name.should eql("test.example.com-short")
      node.sunshine.should eql("in")
      node.something.should eql("else")
      node.run_list.should == ["operations-master", "operations-monitoring"]
    end

    it "should raise an exception if the file cannot be found or read" do
      lambda { node.from_file("/tmp/monkeydiving") }.should raise_error(IOError)
    end
  end

  describe "update_from!" do
    before(:each) do
      node.name("orig")
      node.chef_environment("dev")
      node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      node.normal_attrs = { "one" => { "two" => "seven" } }
      node.run_list << "role[marxist]"
      node.run_list << "role[leninist]"
      node.run_list << "recipe[stalinist]"

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
      node.update_from!(@example)
      node.name.should == "orig"
      node.chef_environment.should == @example.chef_environment
      node.default_attrs.should == @example.default_attrs
      node.override_attrs.should == @example.override_attrs
      node.normal_attrs.should == @example.normal_attrs
      node.run_list.should == @example.run_list
    end

    it "should not update the name of the node" do
      node.should_not_receive(:name).with(@example.name)
      node.update_from!(@example)
    end
  end

  describe "to_hash" do
    it "should serialize itself as a hash" do
      node.chef_environment("dev")
      node.default_attrs = { "one" => { "two" => "three", "four" => "five", "eight" => "nine" } }
      node.override_attrs = { "one" => { "two" => "three", "four" => "six" } }
      node.normal_attrs = { "one" => { "two" => "seven" } }
      node.run_list << "role[marxist]"
      node.run_list << "role[leninist]"
      node.run_list << "recipe[stalinist]"
      h = node.to_hash
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

  describe "converting to or from json" do
    it "should serialize itself as json", :json => true do
      node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
      json = Chef::JSONCompat.to_json(node)
      json.should =~ /json_class/
      json.should =~ /name/
      json.should =~ /chef_environment/
      json.should =~ /normal/
      json.should =~ /default/
      json.should =~ /override/
      json.should =~ /run_list/
    end

    it 'should serialize valid json with a run list', :json => true do
      #This test came about because activesupport mucks with Chef json serialization
      #Test should pass with and without Activesupport
      node.run_list << {"type" => "role", "name" => 'Cthulu'}
      node.run_list << {"type" => "role", "name" => 'Hastur'}
      json = Chef::JSONCompat.to_json(node)
      json.should =~ /\"run_list\":\[\"role\[Cthulu\]\",\"role\[Hastur\]\"\]/
    end

    it "merges the override components into a combined override object" do
      node.attributes.role_override["role override"] = "role override"
      node.attributes.env_override["env override"] = "env override"
      node_for_json = node.for_json
      node_for_json["override"]["role override"].should == "role override"
      node_for_json["override"]["env override"].should == "env override"
    end

    it "merges the default components into a combined default object" do
      node.attributes.role_default["role default"] = "role default"
      node.attributes.env_default["env default"] = "env default"
      node_for_json = node.for_json
      node_for_json["default"]["role default"].should == "role default"
      node_for_json["default"]["env default"].should == "env default"
    end


    it "should deserialize itself from json", :json => true do
      node.from_file(File.expand_path("nodes/test.example.com.rb", CHEF_SPEC_DATA))
      json = Chef::JSONCompat.to_json(node)
      serialized_node = Chef::JSONCompat.from_json(json)
      serialized_node.should be_a_kind_of(Chef::Node)
      serialized_node.name.should eql(node.name)
      serialized_node.chef_environment.should eql(node.chef_environment)
      node.each_attribute do |k,v|
        serialized_node[k].should eql(v)
      end
      serialized_node.run_list.should == node.run_list
    end
  end

  describe "to_s" do
    it "should turn into a string like node[name]" do
      node.name("airplane")
      node.to_s.should eql("node[airplane]")
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
        node.name("monkey")
        node.destroy
      end
    end

    describe "save" do
      it "should update a node if it already exists" do
        node.name("monkey")
        @rest.should_receive(:put_rest).with("nodes/monkey", node).and_return("foo")
        node.save
      end

      it "should not try and create if it can update" do
        node.name("monkey")
        @rest.should_receive(:put_rest).with("nodes/monkey", node).and_return("foo")
        @rest.should_not_receive(:post_rest)
        node.save
      end

      it "should create if it cannot update" do
        node.name("monkey")
        exception = mock("404 error", :code => "404")
        @rest.should_receive(:put_rest).and_raise(Net::HTTPServerException.new("foo", exception))
        @rest.should_receive(:post_rest).with("nodes", node)
        node.save
      end

      describe "when whyrun mode is enabled" do
        before do
          Chef::Config[:why_run] = true
        end
        after do
          Chef::Config[:why_run] = false
        end
        it "should not save" do
          node.name("monkey")
          @rest.should_not_receive(:put_rest)
          @rest.should_not_receive(:post_rest)
          node.save
        end
      end
    end
  end

end
