#
# Author:: Stephen Delano (<stephen@ospcode.com>)
# Author:: Seth Falcon (<seth@ospcode.com>)
# Author:: John Keiser (<jkeiser@ospcode.com>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
require "chef/environment"

describe Chef::Environment do
  before(:each) do
    @environment = Chef::Environment.new
  end

  describe "initialize" do
    it "should be a Chef::Environment" do
      expect(@environment).to be_a_kind_of(Chef::Environment)
    end
  end

  describe "name" do
    it "should let you set the name to a string" do
      expect(@environment.name("production")).to eq("production")
    end

    it "should return the current name" do
      @environment.name("production")
      expect(@environment.name).to eq("production")
    end

    it "should not accept spaces" do
      expect { @environment.name("production environment") }.to raise_error(ArgumentError)
    end

    it "should not accept anything but strings" do
      expect { @environment.name(Array.new) }.to raise_error(ArgumentError)
      expect { @environment.name(Hash.new) }.to raise_error(ArgumentError)
      expect { @environment.name(2) }.to raise_error(ArgumentError)
    end
  end

  describe "description" do
    it "should let you set the description to a string" do
      expect(@environment.description("this is my test environment")).to eq("this is my test environment")
    end

    it "should return the correct description" do
      @environment.description("I like running tests")
      expect(@environment.description).to eq("I like running tests")
    end

    it "should not accept anything but strings" do
      expect { @environment.description(Array.new) }.to raise_error(ArgumentError)
      expect { @environment.description(Hash.new) }.to raise_error(ArgumentError)
      expect { @environment.description(42) }.to raise_error(ArgumentError)
    end
  end

  describe "default attributes" do
    it "should let you set the attributes hash explicitly" do
      expect(@environment.default_attributes({ :one => "two" })).to eq({ :one => "two" })
    end

    it "should let you return the attributes hash" do
      @environment.default_attributes({ :one => "two" })
      expect(@environment.default_attributes).to eq({ :one => "two" })
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      expect { @environment.default_attributes(Array.new) }.to raise_error(ArgumentError)
    end
  end

  describe "override attributes" do
    it "should let you set the attributes hash explicitly" do
      expect(@environment.override_attributes({ :one => "two" })).to eq({ :one => "two" })
    end

    it "should let you return the attributes hash" do
      @environment.override_attributes({ :one => "two" })
      expect(@environment.override_attributes).to eq({ :one => "two" })
    end

    it "should throw an ArgumentError if we aren't a kind of hash" do
      expect { @environment.override_attributes(Array.new) }.to raise_error(ArgumentError)
    end
  end

  describe "cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "= 1.0.0",
        "god"     => "= 2.0.0",
        "apache2" => "= 4.2.0",
      }
    end

    it "should let you set the cookbook versions in a hash" do
      expect(@environment.cookbook_versions(@cookbook_versions)).to eq(@cookbook_versions)
    end

    it "should return the cookbook versions" do
      @environment.cookbook_versions(@cookbook_versions)
      expect(@environment.cookbook_versions).to eq(@cookbook_versions)
    end

    it "should not accept anything but a hash" do
      expect { @environment.cookbook_versions("I am a string!") }.to raise_error(ArgumentError)
      expect { @environment.cookbook_versions(Array.new) }.to raise_error(ArgumentError)
      expect { @environment.cookbook_versions(42) }.to raise_error(ArgumentError)
    end

    it "should validate the hash" do
      expect(Chef::Environment).to receive(:validate_cookbook_versions).with(@cookbook_versions).and_return true
      @environment.cookbook_versions(@cookbook_versions)
    end
  end

  describe "cookbook" do
    it "should set the version of the cookbook in the cookbook_versions hash" do
      @environment.cookbook("apt", "~> 1.2.3")
      expect(@environment.cookbook_versions["apt"]).to eq("~> 1.2.3")
    end

    it "should validate the cookbook version it is passed" do
      expect(Chef::Environment).to receive(:validate_cookbook_version).with(">= 1.2.3").and_return true
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
      expect(@environment.name).to eq("prod")
      expect(@environment.description).to eq(@example.description)
      expect(@environment.cookbook_versions).to eq(@example.cookbook_versions)
    end
  end

  describe "to_hash" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({ :apt => "= 1.2.3" })
      @hash = @environment.to_hash
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        expect(@hash[t]).to eq(@environment.send(t.to_sym))
      end
    end

    it "should include 'json_class'" do
      expect(@hash["json_class"]).to eq("Chef::Environment")
    end

    it "should include 'chef_type'" do
      expect(@hash["chef_type"]).to eq("environment")
    end
  end

  describe "to_json" do
    before(:each) do
      @environment.name("spec")
      @environment.description("Where we run the spec tests")
      @environment.cookbook_versions({ :apt => "= 1.2.3" })
      @json = @environment.to_json
    end

    %w{name description cookbook_versions}.each do |t|
      it "should include '#{t}'" do
        expect(@json).to match(/"#{t}":#{Regexp.escape(Chef::JSONCompat.to_json(@environment.send(t.to_sym)))}/)
      end
    end

    it "should include 'json_class'" do
      expect(@json).to match(/"json_class":"Chef::Environment"/)
    end

    it "should include 'chef_type'" do
      expect(@json).to match(/"chef_type":"environment"/)
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { @environment }
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
          "apache2" => "= 2.0.0",
        },
        "json_class" => "Chef::Environment",
        "chef_type" => "environment",
      }
      @environment = Chef::Environment.from_hash(Chef::JSONCompat.parse(Chef::JSONCompat.to_json(@data)))
    end

    it "should return a Chef::Environment" do
      expect(@environment).to be_a_kind_of(Chef::Environment)
    end

    %w{name description cookbook_versions}.each do |t|
      it "should match '#{t}'" do
        expect(@environment.send(t.to_sym)).to eq(@data[t])
      end
    end
  end

  describe "self.validate_cookbook_versions" do
    before(:each) do
      @cookbook_versions = {
        "apt"     => "= 1.0.0",
        "god"     => "= 2.0.0",
        "apache2" => "= 4.2.0",
      }
    end

    it "should validate the version string of each cookbook" do
      @cookbook_versions.each do |cookbook, version|
        expect(Chef::Environment).to receive(:validate_cookbook_version).with(version).and_return true
      end
      Chef::Environment.validate_cookbook_versions(@cookbook_versions)
    end

    it "should return false if anything other than a hash is passed as the argument" do
      expect(Chef::Environment.validate_cookbook_versions(Array.new)).to eq(false)
      expect(Chef::Environment.validate_cookbook_versions(42)).to eq(false)
      expect(Chef::Environment.validate_cookbook_versions(Chef::CookbookVersion.new("meta"))).to eq(false)
      expect(Chef::Environment.validate_cookbook_versions("cookbook => 1.2.3")).to eq(false)
    end
  end

  describe "self.validate_cookbook_version" do
    it "should validate correct version numbers" do
      expect(Chef::Environment.validate_cookbook_version("= 1.2.3")).to eq(true)
      expect(Chef::Environment.validate_cookbook_version("=1.2.3")).to eq(true)
      expect(Chef::Environment.validate_cookbook_version(">= 0.0.3")).to eq(true)
      expect(Chef::Environment.validate_cookbook_version(">=0.0.3")).to eq(true)
      # A lone version is allowed, interpreted as implicit '='
      expect(Chef::Environment.validate_cookbook_version("1.2.3")).to eq(true)
    end

    it "should return false when an invalid version is given" do
      expect(Chef::Environment.validate_cookbook_version(Chef::CookbookVersion.new("meta"))).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("= 1.2.3a")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("=1.2.3a")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("= 1")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("=1")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("= a")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("=a")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("= 1.2.3.4")).to eq(false)
      expect(Chef::Environment.validate_cookbook_version("=1.2.3.4")).to eq(false)
    end

    describe "in solo mode" do
      before do
        Chef::Config[:solo_legacy_mode] = true
      end

      after do
        Chef::Config[:solo_legacy_mode] = false
      end

      it "should raise an exception" do
        expect do
          Chef::Environment.validate_cookbook_version("= 1.2.3.4")
        end.to raise_error Chef::Exceptions::IllegalVersionConstraint,
                             "Environment cookbook version constraints not allowed in chef-solo"
      end
    end

  end

  describe "when updating from a parameter hash" do
    before do
      @environment = Chef::Environment.new
    end

    it "updates the name from parameters[:name]" do
      @environment.update_from_params(:name => "kurrupt")
      expect(@environment.name).to eq("kurrupt")
    end

    it "validates the name given in the params" do
      expect(@environment.update_from_params(:name => "@$%^&*()")).to be_falsey
      expect(@environment.invalid_fields[:name]).to eq(%q{Option name's value @$%^&*() does not match regular expression /^[\-[:alnum:]_]+$/})
    end

    it "updates the description from parameters[:description]" do
      @environment.update_from_params(:description => "wow, writing your own object mapper is kinda painful")
      expect(@environment.description).to eq("wow, writing your own object mapper is kinda painful")
    end

    it "updates cookbook version constraints from the hash in parameters[:cookbook_version_constraints]" do
      # NOTE: I'm only choosing this (admittedly weird) structure for the hash b/c the better more obvious
      # one, i.e, {:cookbook_version_constraints => {COOKBOOK_NAME => CONSTRAINT}} is difficult to implement
      # the way merb does params
      params = { :name => "superbowl", :cookbook_version => { "0" => "apache2 ~> 1.0.0", "1" => "nginx < 2.0.0" } }
      @environment.update_from_params(params)
      expect(@environment.cookbook_versions).to eq({ "apache2" => "~> 1.0.0", "nginx" => "< 2.0.0" })
    end

    it "validates the cookbook constraints" do
      params = { :cookbook_version => { "0" => "apache2 >>> 1.0.0" } }
      expect(@environment.update_from_params(params)).to be_falsey
      err_msg = @environment.invalid_fields[:cookbook_version]["0"]
      expect(err_msg).to eq("apache2 >>> 1.0.0 is not a valid cookbook constraint")
    end

    it "is not valid if the name is not present" do
      expect(@environment.validate_required_attrs_present).to be_falsey
      expect(@environment.invalid_fields[:name]).to eq("name cannot be empty")
    end

    it "is not valid after updating from params if the name is not present" do
      expect(@environment.update_from_params({})).to be_falsey
      expect(@environment.invalid_fields[:name]).to eq("name cannot be empty")
    end

    it "updates default attributes from a JSON string in params[:attributes]" do
      @environment.update_from_params(:name => "fuuu", :default_attributes => %q|{"fuuu":"RAGE"}|)
      expect(@environment.default_attributes).to eq({ "fuuu" => "RAGE" })
    end

    it "updates override attributes from a JSON string in params[:attributes]" do
      @environment.update_from_params(:name => "fuuu", :override_attributes => %q|{"foo":"override"}|)
      expect(@environment.override_attributes).to eq({ "foo" => "override" })
    end

  end

  describe "api model" do
    before(:each) do
      @rest = double("Chef::ServerAPI")
      allow(Chef::ServerAPI).to receive(:new).and_return(@rest)
      @query = double("Chef::Search::Query")
      allow(Chef::Search::Query).to receive(:new).and_return(@query)
    end

    describe "list" do
      describe "inflated" do
        it "should return a hash of environment names and objects" do
          e1 = double("Chef::Environment", :name => "one")
          expect(@query).to receive(:search).with(:environment).and_yield(e1)
          r = Chef::Environment.list(true)
          expect(r["one"]).to eq(e1)
        end
      end

      it "should return a hash of environment names and urls" do
        expect(@rest).to receive(:get).and_return({ "one" => "http://foo" })
        r = Chef::Environment.list
        expect(r["one"]).to eq("http://foo")
      end
    end
  end

  describe "when loading" do
    describe "in solo mode" do
      before do
        Chef::Config[:solo_legacy_mode] = true
        Chef::Config[:environment_path] = "/var/chef/environments"
      end

      after do
        Chef::Config[:solo_legacy_mode] = false
      end

      it "should get the environment from the environment_path" do
        expect(File).to receive(:directory?).with(Chef::Config[:environment_path]).and_return(true)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.json")).and_return(false)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.rb")).exactly(2).times.and_return(true)
        expect(File).to receive(:readable?).with(File.join(Chef::Config[:environment_path], "foo.rb")).and_return(true)
        role_dsl = "name \"foo\"\ndescription \"desc\"\n"
        expect(IO).to receive(:read).with(File.join(Chef::Config[:environment_path], "foo.rb")).and_return(role_dsl)
        Chef::Environment.load("foo")
      end

      it "should return a Chef::Environment object from JSON" do
        expect(File).to receive(:directory?).with(Chef::Config[:environment_path]).and_return(true)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.json")).and_return(true)
        environment_hash = {
          "name" => "foo",
          "default_attributes" => {
            "foo" => {
              "bar" => 1,
            },
          },
          "json_class" => "Chef::Environment",
          "description" => "desc",
          "chef_type" => "environment",
        }
        expect(IO).to receive(:read).with(File.join(Chef::Config[:environment_path], "foo.json")).and_return(Chef::JSONCompat.to_json(environment_hash))
        environment = Chef::Environment.load("foo")

        expect(environment).to be_a_kind_of(Chef::Environment)
        expect(environment.name).to eq(environment_hash["name"])
        expect(environment.description).to eq(environment_hash["description"])
        expect(environment.default_attributes).to eq(environment_hash["default_attributes"])
      end

      it "should return a Chef::Environment object from Ruby DSL" do
        expect(File).to receive(:directory?).with(Chef::Config[:environment_path]).and_return(true)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.json")).and_return(false)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.rb")).exactly(2).times.and_return(true)
        expect(File).to receive(:readable?).with(File.join(Chef::Config[:environment_path], "foo.rb")).and_return(true)
        role_dsl = "name \"foo\"\ndescription \"desc\"\n"
        expect(IO).to receive(:read).with(File.join(Chef::Config[:environment_path], "foo.rb")).and_return(role_dsl)
        environment = Chef::Environment.load("foo")

        expect(environment).to be_a_kind_of(Chef::Environment)
        expect(environment.name).to eq("foo")
        expect(environment.description).to eq("desc")
      end

      it "should raise an error if the configured environment_path is invalid" do
        expect(File).to receive(:directory?).with(Chef::Config[:environment_path]).and_return(false)

        expect do
          Chef::Environment.load("foo")
        end.to raise_error Chef::Exceptions::InvalidEnvironmentPath, "Environment path '/var/chef/environments' is invalid"
      end

      it "should raise an error if the file does not exist" do
        expect(File).to receive(:directory?).with(Chef::Config[:environment_path]).and_return(true)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.json")).and_return(false)
        expect(File).to receive(:exists?).with(File.join(Chef::Config[:environment_path], "foo.rb")).and_return(false)

        expect do
          Chef::Environment.load("foo")
        end.to raise_error Chef::Exceptions::EnvironmentNotFound, "Environment 'foo' could not be loaded from disk"
      end
    end
  end

end
