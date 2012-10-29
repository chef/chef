#
# Author:: Stephen Delano (<stephen@ospcode.com>)
# Author:: Seth Falcon (<seth@ospcode.com>)
# Author:: John Keiser (<jkeiser@ospcode.com>)
# Copyright:: Copyright 2010-2011 Opscode, Inc.
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
require 'chef/environment'

describe Chef::Environment do
  before(:each) do
    @environment = Chef::Environment.new
  end

  describe "initialize" do
    it "should be a Chef::Environment" do
      @environment.should be_a_kind_of(Chef::Environment)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      @environment.name("production").should == "production"
    end

    it "should return the current name" do
      @environment.name("production")
      @environment.name.should == "production"
    end

    it "should not accept spaces" do
      lambda { @environment.name("production environment") }.should raise_error(ArgumentError)
    end

    it "should not accept anything but strings" do
      lambda { @environment.name(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.name(Hash.new) }.should raise_error(ArgumentError)
      lambda { @environment.name(2) }.should raise_error(ArgumentError)
    end
  end

  describe "description" do
    it "should let you set the description to a string" do
      @environment.description("this is my test environment").should == "this is my test environment"
    end

    it "should return the correct description" do
      @environment.description("I like running tests")
      @environment.description.should == "I like running tests"
    end

    it "should not accept anything but strings" do
      lambda { @environment.description(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.description(Hash.new) }.should raise_error(ArgumentError)
      lambda { @environment.description(42) }.should raise_error(ArgumentError)
    end
  end

  describe "default attributes" do
    it "should let you set the attributes hash explicitly" do
      @environment.default_attributes({ :one => 'two' }).should == { :one => 'two' }
    end

    it "should let you return the attributes hash" do
      @environment.default_attributes({ :one => 'two' })
      @environment.default_attributes.should == { :one => 'two' }
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      lambda { @environment.default_attributes(Array.new) }.should raise_error(ArgumentError)
    end
  end

  describe "override attributes" do
    it "should let you set the attributes hash explicitly" do
      @environment.override_attributes({ :one => 'two' }).should == { :one => 'two' }
    end

    it "should let you return the attributes hash" do
      @environment.override_attributes({ :one => 'two' })
      @environment.override_attributes.should == { :one => 'two' }
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      lambda { @environment.override_attributes(Array.new) }.should raise_error(ArgumentError)
    end
  end

  describe "cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "= 1.0.0",
        "god"     => "= 2.0.0",
        "apache2" => "= 4.2.0"
      }
    end

    it "should let you set the cookbook versions in a hash" do
      @environment.cookbook_versions(@cookbook_versions).should == @cookbook_versions
    end

    it "should return the cookbook versions" do
      @environment.cookbook_versions(@cookbook_versions)
      @environment.cookbook_versions.should == @cookbook_versions
    end

    it "should not accept anything but a hash" do
      lambda { @environment.cookbook_versions("I am a string!") }.should raise_error(ArgumentError)
      lambda { @environment.cookbook_versions(Array.new) }.should raise_error(ArgumentError)
      lambda { @environment.cookbook_versions(42) }.should raise_error(ArgumentError)
    end

    it "should validate the hash" do
      Chef::Environment.should_receive(:validate_cookbook_versions).with(@cookbook_versions).and_return true
      @environment.cookbook_versions(@cookbook_versions)
    end
  end

  describe "cookbook" do
    it "should set the version of the cookbook in the cookbook_versions hash" do
      @environment.cookbook("apt", "~> 1.2.3")
      @environment.cookbook_versions["apt"].should == "~> 1.2.3"
    end

    it "should validate the cookbook version it is passed" do
      Chef::Environment.should_receive(:validate_cookbook_version).with(">= 1.2.3").and_return true
      @environment.cookbook("apt", ">= 1.2.3")
    end
  end

  describe "update_from!" do
    before(:each) do
      @environment.name("prod")
      @environment.description("this is prod")
      @environment.cookbook_versions({ "apt" => "= 1.2.3" })

      @example = Chef::Environment.new
      @example.name("notevenprod")
      @example.description("this is pre-prod")
      @example.cookbook_versions({ "apt" => "= 2.3.4" })
    end

    it "should update everything but name" do
      @environment.update_from!(@example)
      @environment.name.should == "prod"
      @environment.description.should == @example.description
      @environment.cookbook_versions.should == @example.cookbook_versions
    end
  end

  describe "to_hash" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({:apt => "= 1.2.3"})
      @hash = @environment.to_hash
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        @hash[t].should == @environment.send(t.to_sym)
      end
    end

    it "should include 'json_class'" do
      @hash["json_class"].should == "Chef::Environment"
    end

    it "should include 'chef_type'" do
      @hash["chef_type"].should == "environment"
    end
  end

  describe "to_json" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({:apt => "= 1.2.3"})
      @json = @environment.to_json
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        @json.should =~ /"#{t}":#{Regexp.escape(@environment.send(t.to_sym).to_json)}/
      end
    end

    it "should include 'json_class'" do
      @json.should =~ /"json_class":"Chef::Environment"/
    end

    it "should include 'chef_type'" do
      @json.should =~ /"chef_type":"environment"/
    end
  end

  describe "from_json" do
    before(:each) do
      @data = {
        "name" => "production",
        "description" => "We are productive",
        "cookbook_versions" => {
          "apt" => "= 1.2.3",
          "god" => ">= 4.2.0",
          "apache2" => "= 2.0.0"
        },
        "json_class" => "Chef::Environment",
        "chef_type" => "environment"
      }
      @environment = Chef::JSONCompat.from_json(@data.to_json)
    end

    it "should return a Chef::Environment" do
      @environment.should be_a_kind_of(Chef::Environment)
    end

    %w{name description cookbook_versions}.each do |t|
      it "should match '#{t}'" do
        @environment.send(t.to_sym).should == @data[t]
      end
    end
  end

  describe "self.validate_cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "= 1.0.0",
        "god"     => "= 2.0.0",
        "apache2" => "= 4.2.0"
      }
    end

    it "should validate the version string of each cookbook" do
      @cookbook_versions.each do |cookbook, version|
        Chef::Environment.should_receive(:validate_cookbook_version).with(version).and_return true
      end
      Chef::Environment.validate_cookbook_versions(@cookbook_versions)
    end

    it "should return false if anything other than a hash is passed as the argument" do
      Chef::Environment.validate_cookbook_versions(Array.new).should == false
      Chef::Environment.validate_cookbook_versions(42).should == false
      Chef::Environment.validate_cookbook_versions(Chef::CookbookVersion.new("meta")).should == false
      Chef::Environment.validate_cookbook_versions("cookbook => 1.2.3").should == false
    end
  end

  describe "self.validate_cookbook_version" do
    it "should validate correct version numbers" do
      Chef::Environment.validate_cookbook_version("= 1.2.3").should == true
      Chef::Environment.validate_cookbook_version(">= 0.0.3").should == true
      # A lone version is allowed, interpreted as implicit '='
      Chef::Environment.validate_cookbook_version("1.2.3").should == true
    end

    it "should return false when an invalid version is given" do
      Chef::Environment.validate_cookbook_version(Chef::CookbookVersion.new("meta")).should == false
      Chef::Environment.validate_cookbook_version("= 1.2.3a").should == false
      Chef::Environment.validate_cookbook_version("= 1").should == false
      Chef::Environment.validate_cookbook_version("= 1.2.3.4").should == false
    end
  end

  describe "when updating from a parameter hash" do
    before do
      @environment = Chef::Environment.new
    end

    it "updates the name from parameters[:name]" do
      @environment.update_from_params(:name => "kurrupt")
      @environment.name.should == "kurrupt"
    end

    it "validates the name given in the params" do
      @environment.update_from_params(:name => "@$%^&*()").should be_false
      @environment.invalid_fields[:name].should == %q|Option name's value @$%^&*() does not match regular expression /^[\-[:alnum:]_]+$/|
    end

    it "updates the description from parameters[:description]" do
      @environment.update_from_params(:description => "wow, writing your own object mapper is kinda painful")
      @environment.description.should == "wow, writing your own object mapper is kinda painful"
    end

    it "updates cookbook version constraints from the hash in parameters[:cookbook_version_constraints]" do
      # NOTE: I'm only choosing this (admittedly weird) structure for the hash b/c the better more obvious
      # one, i.e, {:cookbook_version_constraints => {COOKBOOK_NAME => CONSTRAINT}} is difficult to implement
      # the way merb does params
      params = {:name=>"superbowl", :cookbook_version => {"0" => "apache2 ~> 1.0.0", "1" => "nginx < 2.0.0"}}
      @environment.update_from_params(params)
      @environment.cookbook_versions.should == {"apache2" => "~> 1.0.0", "nginx" => "< 2.0.0"}
    end

    it "validates the cookbook constraints" do
      params = {:cookbook_version => {"0" => "apache2 >>> 1.0.0"}}
      @environment.update_from_params(params).should be_false
      err_msg = @environment.invalid_fields[:cookbook_version]["0"]
      err_msg.should == "apache2 >>> 1.0.0 is not a valid cookbook constraint"
    end

    it "is not valid if the name is not present" do
      @environment.validate_required_attrs_present.should be_false
      @environment.invalid_fields[:name].should == "name cannot be empty"
    end

    it "is not valid after updating from params if the name is not present" do
      @environment.update_from_params({}).should be_false
      @environment.invalid_fields[:name].should == "name cannot be empty"
    end

    it "updates default attributes from a JSON string in params[:attributes]" do
      @environment.update_from_params(:name => "fuuu", :default_attributes => %q|{"fuuu":"RAGE"}|)
      @environment.default_attributes.should == {"fuuu" => "RAGE"}
    end

    it "updates override attributes from a JSON string in params[:attributes]" do
      @environment.update_from_params(:name => "fuuu", :override_attributes => %q|{"foo":"override"}|)
      @environment.override_attributes.should == {"foo" => "override"}
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
        it "should return a hash of environment names and objects" do
          e1 = mock("Chef::Environment", :name => "one")
          @query.should_receive(:search).with(:environment).and_yield(e1)
          r = Chef::Environment.list(true)
          r["one"].should == e1
        end
      end

      it "should return a hash of environment names and urls" do
        @rest.should_receive(:get_rest).and_return({ "one" => "http://foo" })
        r = Chef::Environment.list
        r["one"].should == "http://foo"
      end
    end
  end

end
