#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
require "chef/cookbook/metadata"

describe Chef::Cookbook::Metadata do

  let(:metadata) { Chef::Cookbook::Metadata.new }

  describe "when comparing for equality" do
    before do
      @fields = %i{name description long_description maintainer
                  maintainer_email license platforms dependencies
                  providing recipes version source_url issues_url
                  privacy ohai_versions chef_versions gems}
    end

    it "does not depend on object identity for equality" do
      expect(metadata).to eq(metadata.dup)
    end

    it "is not equal to another object if it isn't have all of the metadata fields" do
      @fields.each_index do |field_to_remove|
        fields_to_include = @fields.dup
        fields_to_include.delete_at(field_to_remove)
        almost_duck_type = Struct.new(*fields_to_include).new
        @fields.each do |field|
          setter = "#{field}="
          metadata_value = metadata.send(field)
          almost_duck_type.send(setter, metadata_value) if almost_duck_type.respond_to?(setter)
          expect(@mets).not_to eq(almost_duck_type)
        end
      end
    end

    it "is equal to another object if it has equal values for all metadata fields" do
      duck_type = Struct.new(*@fields).new
      @fields.each do |field|
        setter = "#{field}="
        metadata_value = metadata.send(field)
        duck_type.send(setter, metadata_value)
      end
      expect(metadata).to eq(duck_type)
    end

    it "is not equal if any values are different" do
      duck_type_class = Struct.new(*@fields)
      @fields.each do |field_to_change|
        duck_type = duck_type_class.new

        @fields.each do |field|
          setter = "#{field}="
          metadata_value = metadata.send(field)
          duck_type.send(setter, metadata_value)
        end

        duck_type.send("#{field_to_change}=".to_sym, :epic_fail)
        expect(metadata).not_to eq(duck_type)
      end
    end

  end

  describe "when first created" do

    it "has no name" do
      expect(metadata.name).to eq(nil)
    end

    it "has an empty description" do
      expect(metadata.description).to eq("")
    end

    it "has an empty long description" do
      expect(metadata.long_description).to eq("")
    end

    it "defaults to 'all rights reserved' license" do
      expect(metadata.license).to eq("All rights reserved")
    end

    it "has an empty maintainer field" do
      expect(metadata.maintainer).to eq("")
    end

    it "has an empty maintainer_email field" do
      expect(metadata.maintainer_email).to eq("")
    end

    it "has an empty platforms list" do
      expect(metadata.platforms).to eq(Mash.new)
    end

    it "has an empty dependencies list" do
      expect(metadata.dependencies).to eq(Mash.new)
    end

    it "has an empty recipes list" do
      expect(metadata.recipes).to eq(Mash.new)
    end

    it "has an empty source_url string" do
      expect(metadata.source_url).to eq("")
    end

    it "has an empty issues_url string" do
      expect(metadata.issues_url).to eq("")
    end

    it "is not private" do
      expect(metadata.privacy).to eq(false)
    end
  end

  describe "validation" do

    context "when no required fields are set" do

      it "is not valid" do
        expect(metadata).not_to be_valid
      end

      it "has a list of validation errors" do
        expected_errors = ["The `name' attribute is required in cookbook metadata"]
        expect(metadata.errors).to eq(expected_errors)
      end

    end

    context "when all required fields are set" do
      before do
        metadata.name "a-valid-name"
      end

      it "is valid" do
        expect(metadata).to be_valid
      end

      it "has no validation errors" do
        expect(metadata.errors).to be_empty
      end

    end

  end

  describe "adding a supported platform" do
    it "should support adding a supported platform with a single expression" do
      metadata.supports("ubuntu", ">= 8.04")
      expect(metadata.platforms["ubuntu"]).to eq(">= 8.04")
    end
  end

  describe "meta-data attributes" do
    params = {
      maintainer: "Adam Jacob",
      maintainer_email: "adam@opscode.com",
      license: "Apache v2.0",
      description: "Foobar!",
      long_description: "Much Longer\nSeriously",
      version: "0.6.0",
      source_url: "http://example.com",
      issues_url: "http://example.com/issues",
      privacy: true,
    }
    params.sort_by(&:to_s).each do |field, field_value|
      describe field do
        it "should be set-able via #{field}" do
          expect(metadata.send(field, field_value)).to eql(field_value)
        end
        it "should be get-able via #{field}" do
          metadata.send(field, field_value)
          expect(metadata.send(field)).to eql(field_value)
        end
      end
    end

    describe "version transformation" do
      it "should transform an '0.6' version to '0.6.0'" do
        expect(metadata.send(:version, "0.6")).to eql("0.6.0")
      end

      it "should spit out '0.6.0' after transforming '0.6'" do
        metadata.send(:version, "0.6")
        expect(metadata.send(:version)).to eql("0.6.0")
      end
    end
  end

  describe "describing dependencies" do

    dep_types = {
      depends: [ :dependencies, "foo::bar", "> 0.2" ],
      provides: [ :providing, "foo::bar", "<= 0.2" ],
    }
    dep_types.sort_by(&:to_s).each do |dep, dep_args|
      check_with = dep_args.shift
      describe dep do
        it "should be set-able via #{dep}" do
          expect(metadata.send(dep, *dep_args)).to eq(dep_args[1])
        end
        it "should be get-able via #{check_with}" do
          metadata.send(dep, *dep_args)
          expect(metadata.send(check_with)).to eq({ dep_args[0] => dep_args[1] })
        end
      end
    end

    dep_types = {
      depends: [ :dependencies, "foo::bar", ">0.2", "> 0.2" ],
      provides: [ :providing, "foo::bar", "<=0.2", "<= 0.2" ],
    }
    dep_types.sort_by(&:to_s).each do |dep, dep_args|
      check_with = dep_args.shift
      normalized_version = dep_args.pop
      describe dep do
        it "should be set-able and normalized via #{dep}" do
          expect(metadata.send(dep, *dep_args)).to eq(normalized_version)
        end
        it "should be get-able and normalized via #{check_with}" do
          metadata.send(dep, *dep_args)
          expect(metadata.send(check_with)).to eq({ dep_args[0] => normalized_version })
        end
      end
    end

    describe "in the obsoleted format" do
      dep_types = {
        depends: [ "foo::bar", "> 0.2", "< 1.0" ],
        provides: [ "foo::bar", "> 0.2", "< 1.0" ],
      }

      dep_types.each do |dep, dep_args|
        it "for #{dep} raises an informative error instead of vomiting on your shoes" do
          expect { metadata.send(dep, *dep_args) }.to raise_error(Chef::Exceptions::ObsoleteDependencySyntax)
        end
      end
    end

    describe "with obsolete operators" do
      dep_types = {
        depends: [ "foo::bar", ">> 0.2"],
        provides: [ "foo::bar", ">> 0.2"],
      }

      dep_types.each do |dep, dep_args|
        it "for #{dep} raises an informative error instead of vomiting on your shoes" do
          expect { metadata.send(dep, *dep_args) }.to raise_error(Chef::Exceptions::InvalidVersionConstraint)
        end
      end
    end

    it "strips out self-dependencies", chef: "< 13" do
      metadata.name("foo")
      expect(Chef::Log).to receive(:warn).with(
        "Ignoring self-dependency in cookbook foo, please remove it (in the future this will be fatal)."
      )
      metadata.depends("foo")
      expect(metadata.dependencies).to eql({})
    end

    it "errors on self-dependencies", chef: ">= 13" do
      metadata.name("foo")
      expect { metadata.depends("foo") }.to raise_error
      # FIXME: add the error type
    end
  end

  describe "chef_version" do
    def expect_chef_version_works(*args)
      ret = []
      args.each do |arg|
        metadata.send(:chef_version, *arg)
        ret << Gem::Dependency.new("chef", *arg)
      end
      expect(metadata.send(:chef_versions)).to eql(ret)
    end

    it "should work with a single simple constraint" do
      expect_chef_version_works(["~> 12"])
    end

    it "should work with a single complex constraint" do
      expect_chef_version_works([">= 12.0.1", "< 12.5.1"])
    end

    it "should work with multiple simple constraints" do
      expect_chef_version_works(["~> 12.5.1"], ["~> 11.18.10"])
    end

    it "should work with multiple complex constraints" do
      expect_chef_version_works([">= 11.14.2", "< 11.18.10"], [">= 12.2.1", "< 12.5.1"])
    end

    it "should fail validation on a simple pessimistic constraint" do
      expect_chef_version_works(["~> 999.0"])
      expect { metadata.validate_chef_version! }.to raise_error(Chef::Exceptions::CookbookChefVersionMismatch)
    end

    it "should fail validation when that valid chef versions are too big" do
      expect_chef_version_works([">= 999.0", "< 999.9"])
      expect { metadata.validate_chef_version! }.to raise_error(Chef::Exceptions::CookbookChefVersionMismatch)
    end

    it "should fail validation when that valid chef versions are too small" do
      expect_chef_version_works([">= 0.0.1", "< 0.0.9"])
      expect { metadata.validate_chef_version! }.to raise_error(Chef::Exceptions::CookbookChefVersionMismatch)
    end

    it "should fail validation when all ranges fail" do
      expect_chef_version_works([">= 999.0", "< 999.9"], [">= 0.0.1", "< 0.0.9"])
      expect { metadata.validate_chef_version! }.to raise_error(Chef::Exceptions::CookbookChefVersionMismatch)
    end

    it "should pass validation when one constraint passes" do
      expect_chef_version_works([">= 999.0", "< 999.9"], ["= #{Chef::VERSION}"])
      expect { metadata.validate_chef_version! }.not_to raise_error
    end
  end

  describe "ohai_version" do
    def expect_ohai_version_works(*args)
      ret = []
      args.each do |arg|
        metadata.send(:ohai_version, *arg)
        ret << Gem::Dependency.new("ohai", *arg)
      end
      expect(metadata.send(:ohai_versions)).to eql(ret)
    end

    it "should work with a single simple constraint" do
      expect_ohai_version_works(["~> 12"])
    end

    it "should work with a single complex constraint" do
      expect_ohai_version_works([">= 12.0.1", "< 12.5.1"])
    end

    it "should work with multiple simple constraints" do
      expect_ohai_version_works(["~> 12.5.1"], ["~> 11.18.10"])
    end

    it "should work with multiple complex constraints" do
      expect_ohai_version_works([">= 11.14.2", "< 11.18.10"], [">= 12.2.1", "< 12.5.1"])
    end

    it "should fail validation on a simple pessimistic constraint" do
      expect_ohai_version_works(["~> 999.0"])
      expect { metadata.validate_ohai_version! }.to raise_error(Chef::Exceptions::CookbookOhaiVersionMismatch)
    end

    it "should fail validation when that valid chef versions are too big" do
      expect_ohai_version_works([">= 999.0", "< 999.9"])
      expect { metadata.validate_ohai_version! }.to raise_error(Chef::Exceptions::CookbookOhaiVersionMismatch)
    end

    it "should fail validation when that valid chef versions are too small" do
      expect_ohai_version_works([">= 0.0.1", "< 0.0.9"])
      expect { metadata.validate_ohai_version! }.to raise_error(Chef::Exceptions::CookbookOhaiVersionMismatch)
    end

    it "should fail validation when all ranges fail" do
      expect_ohai_version_works([">= 999.0", "< 999.9"], [">= 0.0.1", "< 0.0.9"])
      expect { metadata.validate_ohai_version! }.to raise_error(Chef::Exceptions::CookbookOhaiVersionMismatch)
    end

    it "should pass validation when one constraint passes" do
      expect_ohai_version_works([">= 999.0", "< 999.9"], ["= #{Ohai::VERSION}"])
      expect { metadata.validate_ohai_version! }.not_to raise_error
    end
  end

  describe "gem" do
    def expect_gem_works(*args)
      ret = []
      args.each do |arg|
        metadata.send(:gem, *arg)
        ret << arg
      end
      expect(metadata.send(:gems)).to eql(ret)
    end

    it "works on a simple case" do
      expect_gem_works(["foo", "~> 1.2"])
    end

    it "works if there's two gems" do
      expect_gem_works(["foo", "~> 1.2"], ["bar", "~> 2.0"])
    end

    it "works if there's a more complicated constraint" do
      expect_gem_works(["foo", "~> 1.2"], ["bar", ">= 2.4", "< 4.0"])
    end
  end

  describe "recipes" do
    let(:cookbook) do
      c = Chef::CookbookVersion.new("test_cookbook")
      c.manifest = { all_files: [
        { name: "recipes/default.rb", path: "recipes/default.rb", checksum: "my_only_friend" },
        { name: "recipes/enlighten.rb", path: "recipes/enlighten.rb", checksum: "my_only_friend" },
      ] }
      c
    end

    before(:each) do
      metadata.name("test_cookbook")
      metadata.recipes_from_cookbook_version(cookbook)
    end

    it "should have the names of the recipes" do
      expect(metadata.recipes["test_cookbook"]).to eq("")
      expect(metadata.recipes["test_cookbook::enlighten"]).to eq("")
    end

    it "should let you set the description for a recipe" do
      metadata.recipe "test_cookbook", "It, um... tests stuff?"
      expect(metadata.recipes["test_cookbook"]).to eq("It, um... tests stuff?")
    end

    it "should automatically provide each recipe" do
      expect(metadata.providing.key?("test_cookbook")).to eq(true)
      expect(metadata.providing.key?("test_cookbook::enlighten")).to eq(true)
    end

  end

  describe "json" do
    before(:each) do
      metadata.version "1.0"
      metadata.maintainer "Bobo T. Clown"
      metadata.maintainer_email "bobo@example.com"
      metadata.long_description "I have a long arm!"
      metadata.supports :ubuntu, "> 8.04"
      metadata.depends "bobo", "= 1.0"
      metadata.depends "bubu", "=1.0"
      metadata.depends "bobotclown", "= 1.1"
      metadata.provides "foo(:bar, :baz)"
      metadata.recipe "test_cookbook::enlighten", "is your buddy"
      metadata.version "1.2.3"
      metadata.gem "foo", "~> 1.2"
      metadata.gem "bar", ">= 2.2", "< 4.0"
      metadata.chef_version ">= 11.14.2", "< 11.18.10"
      metadata.chef_version ">= 12.2.1", "< 12.5.1"
      metadata.ohai_version ">= 7.1.0", "< 7.5.0"
      metadata.ohai_version ">= 8.0.1", "< 8.6.0"
    end

    it "should produce the same output from to_json and Chef::JSONCompat" do
      # XXX: fairly certain this is testing ruby method dispatch
      expect(metadata.to_json).to eq(Chef::JSONCompat.to_json(metadata))
    end

    describe "serialize" do

      let(:deserialized_metadata) { Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(metadata)) }

      it "should serialize to a json hash" do
        expect(deserialized_metadata).to be_a_kind_of(Hash)
      end

      %w{
        name
        description
        long_description
        maintainer
        maintainer_email
        license
        platforms
        dependencies
        providing
        recipes
        version
        source_url
        issues_url
        privacy
        gems
      }.each do |t|
        it "should include '#{t}'" do
          expect(deserialized_metadata[t]).to eq(metadata.send(t.to_sym))
        end
      end

      %w{
        ohai_versions
        chef_versions
      }.each do |t|
        it "should include '#{t}'" do
          expect(deserialized_metadata[t]).to eq(metadata.gem_requirements_to_array(*metadata.send(t.to_sym)))
        end
      end
    end

    describe "deserialize" do

      let(:deserialized_metadata) { Chef::Cookbook::Metadata.from_json(Chef::JSONCompat.to_json(metadata)) }

      it "should deserialize to a Chef::Cookbook::Metadata object" do
        expect(deserialized_metadata).to be_a_kind_of(Chef::Cookbook::Metadata)
      end

      %w{
        name
        description
        long_description
        maintainer
        maintainer_email
        license
        platforms
        dependencies
        providing
        recipes
        version
        source_url
        issues_url
        privacy
        chef_versions
        ohai_versions
        gems
      }.each do |t|
        it "should match '#{t}'" do
          expect(deserialized_metadata.send(t.to_sym)).to eq(metadata.send(t.to_sym))
        end
      end
    end

    describe "from_hash" do
      before(:each) do
        @hash = metadata.to_hash
      end

      it "should transform deprecated greater than syntax for :dependencies" do
        @hash[:dependencies.to_s]["foo::bar"] = ">> 0.2"
        deserial = Chef::Cookbook::Metadata.from_hash(@hash)
        expect(deserial.send(:dependencies)["foo::bar"]).to eq("> 0.2")
      end

      it "should transform deprecated less than syntax for :dependencies" do
        @hash[:dependencies.to_s]["foo::bar"] = "<< 0.2"
        deserial = Chef::Cookbook::Metadata.from_hash(@hash)
        expect(deserial.send(:dependencies)["foo::bar"]).to eq("< 0.2")
      end

      it "should ignore multiple dependency constraints for :dependencies" do
        @hash[:dependencies.to_s]["foo::bar"] = [ ">= 1.0", "<= 5.2" ]
        deserial = Chef::Cookbook::Metadata.from_hash(@hash)
        expect(deserial.send(:dependencies)["foo::bar"]).to eq([])
      end

      it "should accept an empty array of dependency constraints for :dependencies" do
        @hash[:dependencies.to_s]["foo::bar"] = []
        deserial = Chef::Cookbook::Metadata.from_hash(@hash)
        expect(deserial.send(:dependencies)["foo::bar"]).to eq([])
      end

      it "should accept single-element arrays of dependency constraints for :dependencies" do
        @hash[:dependencies.to_s]["foo::bar"] = [ ">= 2.0" ]
        deserial = Chef::Cookbook::Metadata.from_hash(@hash)
        expect(deserial.send(:dependencies)["foo::bar"]).to eq(">= 2.0")
      end
    end

    describe "from_file" do
      it "ignores unknown metadata fields in metadata.rb files" do
        expect(Chef::Log).to receive(:trace).with(/ignoring method some_spiffy_new_metadata_field/)
        Tempfile.open("metadata.rb") do |f|
          f.write <<-EOF
            some_spiffy_new_metadata_field "stuff its set to"
          EOF
          f.close
          metadata.from_file(f.path)
        end
      end
    end

    describe "from_json" do
      it "ignores unknown metadata fields in metdata.json files" do
        json = %q{{ "some_spiffy_new_metadata_field": "stuff its set to" }}
        metadata.from_json(json)
      end
    end
  end
end
