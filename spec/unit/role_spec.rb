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
require 'chef/role'

describe Chef::Role do
  before(:each) do
    @role = Chef::Role.new
    @role.name("ops_master")
  end

  it "has a name" do
    @role.name("ops_master").should == "ops_master"
  end

  it "does not accept a name with spaces" do
    lambda { @role.name "ops master" }.should raise_error(ArgumentError)
  end

  it "does not accept non-String objects for the name" do
    lambda { @role.name({}) }.should raise_error(ArgumentError)
  end

  describe "when a run list is set" do

    before do
      @role.run_list(%w{ nginx recipe[ree] role[base]})
    end


    it "returns the run list" do
      @role.run_list.should == %w{ nginx recipe[ree] role[base]}
    end

    describe "and per-environment run lists are set" do
      before do
        @role.name("base")
        @role.run_list(%w{ recipe[nagios::client] recipe[tims-acl::bork]})
        @role.env_run_list["prod"] = Chef::RunList.new(*(@role.run_list.to_a << "recipe[prod-base]"))
        @role.env_run_list["dev"]  = Chef::RunList.new
      end

      it "uses the default run list as *the* run_list" do
        @role.run_list.should == Chef::RunList.new("recipe[nagios::client]", "recipe[tims-acl::bork]")
      end

      it "gives the default run list as the when getting the _default run list" do
        @role.run_list_for("_default").should == @role.run_list
      end

      it "gives an environment specific run list" do
        @role.run_list_for("prod").should == Chef::RunList.new("recipe[nagios::client]", "recipe[tims-acl::bork]", "recipe[prod-base]")
      end

      it "gives the default run list when no run list exists for the given environment" do
        @role.run_list_for("qa").should == @role.run_list
      end

      it "gives the environment specific run list even if it is empty" do
        @role.run_list_for("dev").should == Chef::RunList.new
      end

      it "env_run_lists can only be set with _default run list in it" do
        long_exception_name = Chef::Exceptions::InvalidEnvironmentRunListSpecification
        lambda {@role.env_run_lists({})}.should raise_error(long_exception_name)
      end

    end


    describe "using the old #recipes API" do
      it "should let you set the recipe array" do
        @role.recipes([ "one", "two" ]).should == [ "one", "two" ]
      end

      it "should let you return the recipe array" do
        @role.recipes([ "one", "two" ])
        @role.recipes.should == [ "one", "two" ]
      end

      it "should not list roles in the recipe array" do
        @role.run_list([ "one", "role[two]"])
        @role.recipes.should == [ "recipe[one]", "role[two]" ]
      end

    end

  end



  describe "default_attributes" do
    it "should let you set the default attributes hash explicitly" do
      @role.default_attributes({ :one => 'two' }).should == { :one => 'two' }
    end

    it "should let you return the default attributes hash" do
      @role.default_attributes({ :one => 'two' })
      @role.default_attributes.should == { :one => 'two' }
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      lambda { @role.default_attributes(Array.new) }.should raise_error(ArgumentError)
    end
  end

  describe "override_attributes" do
    it "should let you set the override attributes hash explicitly" do
      @role.override_attributes({ :one => 'two' }).should == { :one => 'two' }
    end

    it "should let you return the override attributes hash" do
      @role.override_attributes({ :one => 'two' })
      @role.override_attributes.should == { :one => 'two' }
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      lambda { @role.override_attributes(Array.new) }.should raise_error(ArgumentError)
    end
  end

  describe "update_from!" do
    before(:each) do
      @role.name('mars_volta')
      @role.description('Great band!')
      @role.run_list('one', 'two', 'role[a]')
      @role.default_attributes({ :el_groupo => 'nuevo' })
      @role.override_attributes({ :deloused => 'in the comatorium' })

      @example = Chef::Role.new
      @example.name('newname')
      @example.description('Really Great band!')
      @example.run_list('alpha', 'bravo', 'role[alpha]')
      @example.default_attributes({ :el_groupo => 'nuevo dos' })
      @example.override_attributes({ :deloused => 'in the comatorium XOXO' })
    end

    it "should update all fields except for name" do
      @role.update_from!(@example)
      @role.name.should == "mars_volta"
      @role.description.should == @example.description
      @role.run_list.should == @example.run_list
      @role.default_attributes.should == @example.default_attributes
      @role.override_attributes.should == @example.override_attributes
    end
  end

  describe "when serialized as JSON", :json => true do
    before(:each) do
      @role.name('mars_volta')
      @role.description('Great band!')
      @role.run_list('one', 'two', 'role[a]')
      @role.default_attributes({ :el_groupo => 'nuevo' })
      @role.override_attributes({ :deloused => 'in the comatorium' })
      @serialized_role = Chef::JSONCompat.to_json(@role)
    end

    it "should serialize to a json hash" do
      Chef::JSONCompat.to_json(@role).should match(/^\{.+\}$/)
    end

    it "includes the name in the JSON output" do
      @serialized_role.should =~ /"name":"mars_volta"/
    end

    it "includes its description in the JSON" do
      @serialized_role.should match(/"description":"Great band!"/)
    end

    it "should include 'default_attributes'" do
      @serialized_role.should =~ /"default_attributes":\{"el_groupo":"nuevo"\}/
    end

    it "should include 'override_attributes'" do
      @serialized_role.should =~ /"override_attributes":\{"deloused":"in the comatorium"\}/
    end

    it "should include 'run_list'" do
      #Activesupport messes with Chef json formatting
      #This test should pass with and without activesupport
      @serialized_role.should =~ /"run_list":\["recipe\[one\]","recipe\[two\]","role\[a\]"\]/
    end

    describe "and it has per-environment run lists" do
      before do
        @role.env_run_lists("_default" => ['one', 'two', 'role[a]'], "production" => ['role[monitoring]', 'role[auditing]', 'role[apache]'], "dev" => ["role[nginx]"])
        @serialized_role = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(@role), :create_additions => false)
      end

      it "includes the per-environment run lists" do
        #Activesupport messes with Chef json formatting
        #This test should pass with and without activesupport
        @serialized_role["env_run_lists"]["production"].should == ['role[monitoring]', 'role[auditing]', 'role[apache]']
        @serialized_role["env_run_lists"]["dev"].should == ["role[nginx]"]
      end

      it "does not include the default environment in the per-environment run lists" do
        @serialized_role["env_run_lists"].should_not have_key("_default")
      end

    end
  end

  describe "when created from JSON", :json => true do
    before(:each) do
      @role.name('mars_volta')
      @role.description('Great band!')
      @role.run_list('one', 'two', 'role[a]')
      @role.default_attributes({ 'el_groupo' => 'nuevo' })
      @role.override_attributes({ 'deloused' => 'in the comatorium' })
      @deserial = Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(@role))
    end

    it "should deserialize to a Chef::Role object" do
      @deserial.should be_a_kind_of(Chef::Role)
    end

    %w{
      name
      description
      default_attributes
      override_attributes
      run_list
    }.each do |t|
      it "should preserves the '#{t}' attribute from the JSON object" do
        @deserial.send(t.to_sym).should == @role.send(t.to_sym)
      end
    end
  end

  describe "when loading from disk" do
    it "should return a Chef::Role object from JSON" do
      File.should_receive(:exists?).with(File.join(Chef::Config[:role_path], 'lolcat.json')).exactly(1).times.and_return(true)
      IO.should_receive(:read).with(File.join(Chef::Config[:role_path], 'lolcat.json')).and_return('{"name": "ceiling_cat", "json_class": "Chef::Role" }')
      @role.should be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should return a Chef::Role object from a Ruby DSL" do
      File.should_receive(:exists?).with(File.join(Chef::Config[:role_path], 'lolcat.json')).exactly(1).times.and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:role_path], 'lolcat.rb')).exactly(2).times.and_return(true)
      File.should_receive(:readable?).with(File.join(Chef::Config[:role_path], 'lolcat.rb')).exactly(1).times.and_return(true)
      ROLE_DSL=<<-EOR
name "ceiling_cat"
description "like Aliens, but furry"
EOR
      IO.should_receive(:read).with(File.join(Chef::Config[:role_path], 'lolcat.rb')).and_return(ROLE_DSL)
      @role.should be_a_kind_of(Chef::Role)
      @role.class.from_disk("lolcat")
    end

    it "should raise an exception if the file does not exist" do
      File.should_receive(:exists?).with(File.join(Chef::Config[:role_path], 'lolcat.json')).exactly(1).times.and_return(false)
      File.should_receive(:exists?).with(File.join(Chef::Config[:role_path], 'lolcat.rb')).exactly(1).times.and_return(false)
      lambda {@role.class.from_disk("lolcat")}.should raise_error(Chef::Exceptions::RoleNotFound)
    end
  end
end

