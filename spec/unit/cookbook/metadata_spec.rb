#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Copyright:: Copyright 2008-2010 Opscode, Inc.
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
require 'chef/cookbook/metadata'

describe Chef::Cookbook::Metadata do

  let(:metadata) { Chef::Cookbook::Metadata.new }

  describe "when comparing for equality" do
    before do
      @fields = [ :name, :description, :long_description, :maintainer,
                  :maintainer_email, :license, :platforms, :dependencies,
                  :recommendations, :suggestions, :conflicting, :providing,
                  :replacing, :attributes, :groupings, :recipes, :version]
    end

    it "does not depend on object identity for equality" do
      metadata.should == metadata.dup
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
          @mets.should_not == almost_duck_type
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
      metadata.should == duck_type
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
        metadata.should_not == duck_type
      end
    end

  end

  describe "when first created" do

    it "has no name" do
      metadata.name.should eq(nil)
    end

    it "has an empty description" do
      metadata.description.should eq("")
    end

    it "has an empty long description" do
      metadata.long_description.should eq("")
    end

    it "defaults to 'all rights reserved' license" do
      metadata.license.should eq("All rights reserved")
    end

    it "has an empty maintainer field" do
      metadata.maintainer.should eq(nil)
    end

    it "has an empty maintainer_email field" do
      metadata.maintainer.should eq(nil)
    end

    it "has an empty platforms list" do
      metadata.platforms.should eq(Mash.new)
    end

    it "has an empty dependencies list" do
      metadata.dependencies.should eq(Mash.new)
    end

    it "has an empty recommends list" do
      metadata.recommendations.should eq(Mash.new)
    end

    it "has an empty suggestions list" do
      metadata.suggestions.should eq(Mash.new)
    end

    it "has an empty conflicts list" do
      metadata.conflicting.should eq(Mash.new)
    end

    it "has an empty replaces list" do
      metadata.replacing.should eq(Mash.new)
    end

    it "has an empty attributes list" do
      metadata.attributes.should eq(Mash.new)
    end

    it "has an empty groupings list" do
      metadata.groupings.should eq(Mash.new)
    end

    it "has an empty recipes list" do
      metadata.recipes.should eq(Mash.new)
    end

  end

  describe "validation" do

    context "when no required fields are set" do

      it "is not valid" do
        metadata.should_not be_valid
      end

      it "has a list of validation errors" do
        expected_errors = ["The `name' attribute is required in cookbook metadata"]
        metadata.errors.should eq(expected_errors)
      end

    end

    context "when all required fields are set" do
      before do
        metadata.name "a-valid-name"
      end

      it "is valid" do
        metadata.should be_valid
      end

      it "has no validation errors" do
        metadata.errors.should be_empty
      end

    end

  end

  describe "adding a supported platform" do
    it "should support adding a supported platform with a single expression" do
      metadata.supports("ubuntu", ">= 8.04")
      metadata.platforms["ubuntu"].should == '>= 8.04'
    end
  end

  describe "meta-data attributes" do
    params = {
      :maintainer => "Adam Jacob",
      :maintainer_email => "adam@opscode.com",
      :license => "Apache v2.0",
      :description => "Foobar!",
      :long_description => "Much Longer\nSeriously",
      :version => "0.6.0"
    }
    params.sort { |a,b| a.to_s <=> b.to_s }.each do |field, field_value|
      describe field do
        it "should be set-able via #{field}" do
          metadata.send(field, field_value).should eql(field_value)
        end
        it "should be get-able via #{field}" do
          metadata.send(field, field_value)
          metadata.send(field).should eql(field_value)
        end
      end
    end

    describe "version transformation" do
      it "should transform an '0.6' version to '0.6.0'" do
        metadata.send(:version, "0.6").should eql("0.6.0")
      end

      it "should spit out '0.6.0' after transforming '0.6'" do
        metadata.send(:version, "0.6")
        metadata.send(:version).should eql("0.6.0")
      end
    end
  end

  describe "describing dependencies" do

    dep_types = {
      :depends     => [ :dependencies, "foo::bar", "> 0.2" ],
      :recommends  => [ :recommendations, "foo::bar", ">= 0.2" ],
      :suggests    => [ :suggestions, "foo::bar", "> 0.2" ],
      :conflicts   => [ :conflicting, "foo::bar", "~> 0.2" ],
      :provides    => [ :providing, "foo::bar", "<= 0.2" ],
      :replaces    => [ :replacing, "foo::bar", "= 0.2.1" ],
    }
    dep_types.sort { |a,b| a.to_s <=> b.to_s }.each do |dep, dep_args|
      check_with = dep_args.shift
      describe dep do
        it "should be set-able via #{dep}" do
          metadata.send(dep, *dep_args).should == dep_args[1]
        end
        it "should be get-able via #{check_with}" do
          metadata.send(dep, *dep_args)
          metadata.send(check_with).should == { dep_args[0] => dep_args[1] }
        end
      end
    end

    dep_types = {
      :depends     => [ :dependencies, "foo::bar", ">0.2", "> 0.2" ],
      :recommends  => [ :recommendations, "foo::bar", ">=0.2", ">= 0.2" ],
      :suggests    => [ :suggestions, "foo::bar", ">0.2", "> 0.2" ],
      :conflicts   => [ :conflicting, "foo::bar", "~>0.2", "~> 0.2" ],
      :provides    => [ :providing, "foo::bar", "<=0.2", "<= 0.2" ],
      :replaces    => [ :replacing, "foo::bar", "=0.2.1", "= 0.2.1" ],
    }
    dep_types.sort { |a,b| a.to_s <=> b.to_s }.each do |dep, dep_args|
      check_with = dep_args.shift
      normalized_version = dep_args.pop
      describe dep do
        it "should be set-able and normalized via #{dep}" do
          metadata.send(dep, *dep_args).should == normalized_version
        end
        it "should be get-able and normalized via #{check_with}" do
          metadata.send(dep, *dep_args)
          metadata.send(check_with).should == { dep_args[0] => normalized_version }
        end
      end
    end


    describe "in the obsoleted format" do
      dep_types = {
        :depends     => [ "foo::bar", "> 0.2", "< 1.0" ],
        :recommends  => [ "foo::bar", ">= 0.2", "< 1.0" ],
        :suggests    => [ "foo::bar", "> 0.2", "< 1.0" ],
        :conflicts   => [ "foo::bar", "> 0.2", "< 1.0" ],
        :provides    => [ "foo::bar", "> 0.2", "< 1.0" ],
        :replaces    => [ "foo::bar", "> 0.2.1", "< 1.0" ],
      }

      dep_types.each do |dep, dep_args|
        it "for #{dep} raises an informative error instead of vomiting on your shoes" do
          lambda {metadata.send(dep, *dep_args)}.should raise_error(Chef::Exceptions::ObsoleteDependencySyntax)
        end
      end
    end


    describe "with obsolete operators" do
      dep_types = {
        :depends     => [ "foo::bar", ">> 0.2"],
        :recommends  => [ "foo::bar", ">> 0.2"],
        :suggests    => [ "foo::bar", ">> 0.2"],
        :conflicts   => [ "foo::bar", ">> 0.2"],
        :provides    => [ "foo::bar", ">> 0.2"],
        :replaces    => [ "foo::bar", ">> 0.2.1"],
      }

      dep_types.each do |dep, dep_args|
        it "for #{dep} raises an informative error instead of vomiting on your shoes" do
          lambda {metadata.send(dep, *dep_args)}.should raise_error(Chef::Exceptions::InvalidVersionConstraint)
        end
      end
    end
  end

  describe "attribute groupings" do
    it "should allow you set a grouping" do
      group = {
        "title" => "MySQL Tuning",
        "description" => "Setting from the my.cnf file that allow you to tune your mysql server"
      }
      metadata.grouping("/db/mysql/databases/tuning", group).should == group
    end
    it "should not accept anything but a string for display_name" do
      lambda {
        metadata.grouping("db/mysql/databases", :title => "foo")
      }.should_not raise_error
      lambda {
        metadata.grouping("db/mysql/databases", :title => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but a string for the description" do
      lambda {
        metadata.grouping("db/mysql/databases", :description => "foo")
      }.should_not raise_error
      lambda {
        metadata.grouping("db/mysql/databases", :description => Hash.new)
      }.should raise_error(ArgumentError)
    end
  end

  describe "cookbook attributes" do
    it "should allow you set an attributes metadata" do
      attrs = {
        "display_name" => "MySQL Databases",
        "description" => "Description of MySQL",
        "choice" => ['dedicated', 'shared'],
        "calculated" => false,
        "type" => 'string',
        "required" => 'recommended',
        "recipes" => [ "mysql::server", "mysql::master" ],
        "default" => [ ]
      }
      metadata.attribute("/db/mysql/databases", attrs).should == attrs
    end

    it "should not accept anything but a string for display_name" do
      lambda {
        metadata.attribute("db/mysql/databases", :display_name => "foo")
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :display_name => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but a string for the description" do
      lambda {
        metadata.attribute("db/mysql/databases", :description => "foo")
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :description => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but an array of strings for choice" do
      lambda {
        metadata.attribute("db/mysql/databases", :choice => ['dedicated', 'shared'])
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :choice => [10, 'shared'])
      }.should raise_error(ArgumentError)
      lambda {
        metadata.attribute("db/mysql/databases", :choice => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set choice to empty array by default" do
      metadata.attribute("db/mysql/databases", {})
      metadata.attributes["db/mysql/databases"][:choice].should == []
    end

     it "should let calculated be true or false" do
       lambda {
         metadata.attribute("db/mysql/databases", :calculated => true)
       }.should_not raise_error
       lambda {
         metadata.attribute("db/mysql/databases", :calculated => false)
       }.should_not raise_error
       lambda {
         metadata.attribute("db/mysql/databases", :calculated => Hash.new)
       }.should raise_error(ArgumentError)
     end

     it "should set calculated to false by default" do
       metadata.attribute("db/mysql/databases", {})
       metadata.attributes["db/mysql/databases"][:calculated].should == false
     end

    it "accepts String for the attribute type" do
      lambda {
        metadata.attribute("db/mysql/databases", :type => "string")
      }.should_not raise_error
    end

    it "accepts Array for the attribute type" do
      lambda {
        metadata.attribute("db/mysql/databases", :type => "array")
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :type => Array.new)
      }.should raise_error(ArgumentError)
    end

    it "accepts symbol for the attribute type" do
      lambda {
        metadata.attribute("db/mysql/databases", :type => "symbol")
      }.should_not raise_error
    end

     it "should let type be hash (backwards compatability only)" do
      lambda {
        metadata.attribute("db/mysql/databases", :type => "hash")
      }.should_not raise_error
    end

    it "should let required be required, recommended or optional" do
      lambda {
        metadata.attribute("db/mysql/databases", :required => 'required')
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :required => 'recommended')
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :required => 'optional')
      }.should_not raise_error
    end

    it "should convert required true to required" do
      lambda {
        metadata.attribute("db/mysql/databases", :required => true)
      }.should_not raise_error
      #attrib = metadata.attributes["db/mysql/databases"][:required].should == "required"
    end

    it "should convert required false to optional" do
      lambda {
        metadata.attribute("db/mysql/databases", :required => false)
      }.should_not raise_error
      #attrib = metadata.attributes["db/mysql/databases"][:required].should == "optional"
    end

    it "should set required to 'optional' by default" do
      metadata.attribute("db/mysql/databases", {})
      metadata.attributes["db/mysql/databases"][:required].should == 'optional'
    end

    it "should make sure recipes is an array" do
      lambda {
        metadata.attribute("db/mysql/databases", :recipes => [])
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :required => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set recipes to an empty array by default" do
      metadata.attribute("db/mysql/databases", {})
      metadata.attributes["db/mysql/databases"][:recipes].should == []
    end

    it "should allow the default value to be a string, array, hash, boolean or numeric" do
      lambda {
        metadata.attribute("db/mysql/databases", :default => [])
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :default => {})
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :default => "alice in chains")
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :default => 1337)
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :default => true)
      }.should_not raise_error
      lambda {
        metadata.attribute("db/mysql/databases", :required => :not_gonna_do_it)
      }.should raise_error(ArgumentError)
    end

    it "should limit the types allowed in the choice array" do
      options = {
        :type => "string",
        :choice => [ "test1", "test2" ],
        :default => "test1"
      }
      lambda {
        metadata.attribute("test_cookbook/test", options)
      }.should_not raise_error

      options = {
        :type => "boolean",
        :choice => [ true, false ],
        :default => true
      }
      lambda {
        metadata.attribute("test_cookbook/test", options)
      }.should_not raise_error

      options = {
        :type => "numeric",
        :choice => [ 1337, 420 ],
        :default => 1337
      }
      lambda {
        metadata.attribute("test_cookbook/test", options)
      }.should_not raise_error

      options = {
        :type => "numeric",
        :choice => [ true, "false" ],
        :default => false
      }
      lambda {
        metadata.attribute("test_cookbook/test", options)
      }.should raise_error
    end

    it "should error if default used with calculated" do
      lambda {
        attrs = {
          :calculated => true,
          :default => [ "I thought you said calculated" ]
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
      lambda {
        attrs = {
          :calculated => true,
          :default => "I thought you said calculated"
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
    end

    it "should allow a default that is a choice" do
      lambda {
        attrs = {
          :choice => [ "a", "b", "c"],
          :default => "b"
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should_not raise_error
      lambda {
        attrs = {
          :choice => [ "a", "b", "c", "d", "e"],
          :default => ["b", "d"]
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should_not raise_error
     end

    it "should error if default is not a choice" do
      lambda {
        attrs = {
          :choice => [ "a", "b", "c"],
          :default => "d"
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
      lambda {
        attrs = {
          :choice => [ "a", "b", "c", "d", "e"],
          :default => ["b", "z"]
        }
        metadata.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
    end
  end

  describe "recipes" do
    let(:cookbook) do
      c = Chef::CookbookVersion.new('test_cookbook')
      c.recipe_files = [ "default.rb", "enlighten.rb" ]
      c
    end

    before(:each) do
      metadata.name("test_cookbook")
      metadata.recipes_from_cookbook_version(cookbook)
    end

    it "should have the names of the recipes" do
      metadata.recipes["test_cookbook"].should == ""
      metadata.recipes["test_cookbook::enlighten"].should == ""
    end

    it "should let you set the description for a recipe" do
      metadata.recipe "test_cookbook", "It, um... tests stuff?"
      metadata.recipes["test_cookbook"].should == "It, um... tests stuff?"
    end

    it "should automatically provide each recipe" do
      metadata.providing.has_key?("test_cookbook").should == true
      metadata.providing.has_key?("test_cookbook::enlighten").should == true
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
      metadata.recommends "snark", "< 3.0"
      metadata.suggests "kindness", "> 2.0"
      metadata.conflicts "hatred"
      metadata.provides "foo(:bar, :baz)"
      metadata.replaces "snarkitron"
      metadata.recipe "test_cookbook::enlighten", "is your buddy"
      metadata.attribute "bizspark/has_login",
        :display_name => "You have nothing"
      metadata.version "1.2.3"
    end

    it "should produce the same output from to_json and Chef::JSONCompat" do
      expect(metadata.to_json).to eq(Chef::JSONCompat.to_json(metadata))
    end

    describe "serialize" do

      let(:deserialized_metadata) { Chef::JSONCompat.from_json(Chef::JSONCompat.to_json(metadata)) }

      it "should serialize to a json hash" do
        deserialized_metadata.should be_a_kind_of(Hash)
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
        suggestions
        recommendations
        conflicting
        providing
        replacing
        attributes
        recipes
        version
      }.each do |t|
        it "should include '#{t}'" do
          deserialized_metadata[t].should == metadata.send(t.to_sym)
        end
      end
    end

    describe "deserialize" do

      let(:deserialized_metadata) { Chef::Cookbook::Metadata.from_json(Chef::JSONCompat.to_json(metadata)) }


      it "should deserialize to a Chef::Cookbook::Metadata object" do
        deserialized_metadata.should be_a_kind_of(Chef::Cookbook::Metadata)
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
        suggestions
        recommendations
        conflicting
        providing
        replacing
        attributes
        recipes
        version
      }.each do |t|
        it "should match '#{t}'" do
          deserialized_metadata.send(t.to_sym).should == metadata.send(t.to_sym)
        end
      end
    end

    describe "from_hash" do
      before(:each) do
        @hash = metadata.to_hash
      end

      [:dependencies,
       :recommendations,
       :suggestions,
       :conflicting,
       :replacing].each do |to_check|
        it "should transform deprecated greater than syntax for :#{to_check.to_s}" do
          @hash[to_check.to_s]["foo::bar"] = ">> 0.2"
          deserial = Chef::Cookbook::Metadata.from_hash(@hash)
          deserial.send(to_check)["foo::bar"].should == '> 0.2'
        end

        it "should transform deprecated less than syntax for :#{to_check.to_s}" do
          @hash[to_check.to_s]["foo::bar"] = "<< 0.2"
          deserial = Chef::Cookbook::Metadata.from_hash(@hash)
          deserial.send(to_check)["foo::bar"].should == '< 0.2'
        end

        it "should ignore multiple dependency constraints for :#{to_check.to_s}" do
          @hash[to_check.to_s]["foo::bar"] = [ ">= 1.0", "<= 5.2" ]
          deserial = Chef::Cookbook::Metadata.from_hash(@hash)
          deserial.send(to_check)["foo::bar"].should == []
        end

        it "should accept an empty array of dependency constraints for :#{to_check.to_s}" do
          @hash[to_check.to_s]["foo::bar"] = []
          deserial = Chef::Cookbook::Metadata.from_hash(@hash)
          deserial.send(to_check)["foo::bar"].should == []
        end

        it "should accept single-element arrays of dependency constraints for :#{to_check.to_s}" do
          @hash[to_check.to_s]["foo::bar"] = [ ">= 2.0" ]
          deserial = Chef::Cookbook::Metadata.from_hash(@hash)
          deserial.send(to_check)["foo::bar"].should == ">= 2.0"
        end
      end
    end

  end

end
