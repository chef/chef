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
  before(:each) do
    @cookbook = Chef::CookbookVersion.new('test_cookbook')
    @meta = Chef::Cookbook::Metadata.new(@cookbook)
  end

  describe "when comparing for equality" do
    before do
      @fields = [ :name, :description, :long_description, :maintainer,
                  :maintainer_email, :license, :platforms, :dependencies,
                  :recommendations, :suggestions, :conflicting, :providing,
                  :replacing, :attributes, :groupings, :recipes, :version]
    end

    it "does not depend on object identity for equality" do
      @meta.should == @meta.dup
    end

    it "is not equal to another object if it isn't have all of the metadata fields" do
      @fields.each_index do |field_to_remove|
        fields_to_include = @fields.dup
        fields_to_include.delete_at(field_to_remove)
        almost_duck_type = Struct.new(*fields_to_include).new
        @fields.each do |field|
          setter = "#{field}="
          metadata_value = @meta.send(field)
          almost_duck_type.send(setter, metadata_value) if almost_duck_type.respond_to?(setter)
          @mets.should_not == almost_duck_type
        end
      end
    end

    it "is equal to another object if it has equal values for all metadata fields" do
      duck_type = Struct.new(*@fields).new
      @fields.each do |field|
        setter = "#{field}="
        metadata_value = @meta.send(field)
        duck_type.send(setter, metadata_value)
      end
      @meta.should == duck_type
    end

    it "is not equal if any values are different" do
      duck_type_class = Struct.new(*@fields)
      @fields.each do |field_to_change|
        duck_type = duck_type_class.new

        @fields.each do |field|
          setter = "#{field}="
          metadata_value = @meta.send(field)
          duck_type.send(setter, metadata_value)
        end

        field_to_change

        duck_type.send("#{field_to_change}=".to_sym, :epic_fail)
        @meta.should_not == duck_type
      end
    end

  end

  describe "when first created" do
    it "should return a Chef::Cookbook::Metadata object" do
      @meta.should be_a_kind_of(Chef::Cookbook::Metadata)
    end
    
    it "should allow a cookbook as the first argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook) }.should_not raise_error
    end

    it "should allow an maintainer name for the second argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown') }.should_not raise_error
    end

    it "should set the maintainer name from the second argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown') 
      md.maintainer.should == 'Bobo T. Clown'
    end

    it "should allow an maintainer email for the third argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co') }.should_not raise_error
    end

    it "should set the maintainer email from the third argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co') 
      md.maintainer_email.should == 'bobo@clown.co'
    end

    it "should allow a license for the fourth argument" do
      lambda { Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co', 'Clown License v1') }.should_not raise_error
    end

    it "should set the license from the fourth argument" do
      md = Chef::Cookbook::Metadata.new(@cookbook, 'Bobo T. Clown', 'bobo@clown.co', 'Clown License v1') 
      md.license.should == 'Clown License v1'
    end
  end 

  describe "cookbook" do
    it "should return the cookbook we were initialized with" do
      @meta.cookbook.should eql(@cookbook)
    end
  end

  describe "name" do
    it "should return the name of the cookbook" do
      @meta.name.should eql(@cookbook.name)
    end
  end

  describe "platforms" do
    it "should return the current platform hash" do
      @meta.platforms.should be_a_kind_of(Hash)  
    end
  end

  describe "adding a supported platform" do
    it "should support adding a supported platform with a single expression" do
      @meta.supports("ubuntu", ">= 8.04")
      @meta.platforms["ubuntu"].should == '>= 8.04'
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
          @meta.send(field, field_value).should eql(field_value)
        end
        it "should be get-able via #{field}" do
          @meta.send(field, field_value)
          @meta.send(field).should eql(field_value)
        end
      end
    end

    describe "version transformation" do
      it "should transform an '0.6' version to '0.6.0'" do
        @meta.send(:version, "0.6").should eql("0.6.0")
      end

      it "should spit out '0.6.0' after transforming '0.6'" do
        @meta.send(:version, "0.6")
        @meta.send(:version).should eql("0.6.0")
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
          @meta.send(dep, *dep_args).should == dep_args[1]
        end
        it "should be get-able via #{check_with}" do
          @meta.send(dep, *dep_args)
          @meta.send(check_with).should == { dep_args[0] => dep_args[1] }
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
          lambda {@meta.send(dep, *dep_args)}.should raise_error(Chef::Exceptions::ObsoleteDependencySyntax)
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
          lambda {@meta.send(dep, *dep_args)}.should raise_error(Chef::Exceptions::InvalidVersionConstraint)
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
      @meta.grouping("/db/mysql/databases/tuning", group).should == group
    end
    it "should not accept anything but a string for display_name" do
      lambda {
        @meta.grouping("db/mysql/databases", :title => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.grouping("db/mysql/databases", :title => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but a string for the description" do
      lambda {
        @meta.grouping("db/mysql/databases", :description => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.grouping("db/mysql/databases", :description => Hash.new)
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
      @meta.attribute("/db/mysql/databases", attrs).should == attrs
    end

    it "should not accept anything but a string for display_name" do
      lambda {
        @meta.attribute("db/mysql/databases", :display_name => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :display_name => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but a string for the description" do
      lambda {
        @meta.attribute("db/mysql/databases", :description => "foo")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :description => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should not accept anything but an array of strings for choice" do
      lambda {
        @meta.attribute("db/mysql/databases", :choice => ['dedicated', 'shared'])
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :choice => [10, 'shared'])
      }.should raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :choice => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set choice to empty array by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:choice].should == []
    end
    
     it "should let calculated be true or false" do
       lambda {
         @meta.attribute("db/mysql/databases", :calculated => true)
       }.should_not raise_error(ArgumentError)
       lambda {
         @meta.attribute("db/mysql/databases", :calculated => false)
       }.should_not raise_error(ArgumentError)
       lambda {
         @meta.attribute("db/mysql/databases", :calculated => Hash.new)
       }.should raise_error(ArgumentError)
     end
 
     it "should set calculated to false by default" do
       @meta.attribute("db/mysql/databases", {})
       @meta.attributes["db/mysql/databases"][:calculated].should == false
     end

    it "accepts String for the attribute type" do
      lambda {
        @meta.attribute("db/mysql/databases", :type => "string")
      }.should_not raise_error(ArgumentError)
    end

    it "accepts Array for the attribute type" do
      lambda {
        @meta.attribute("db/mysql/databases", :type => "array")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :type => Array.new)
      }.should raise_error(ArgumentError)
    end

    it "accepts symbol for the attribute type" do
      lambda {
        @meta.attribute("db/mysql/databases", :type => "symbol")
      }.should_not raise_error(ArgumentError)
    end
    
     it "should let type be hash (backwards compatability only)" do
      lambda {
        @meta.attribute("db/mysql/databases", :type => "hash")
      }.should_not raise_error(ArgumentError)
    end

    it "should let required be required, recommended or optional" do
      lambda {
        @meta.attribute("db/mysql/databases", :required => 'required')
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => 'recommended')
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => 'optional')
      }.should_not raise_error(ArgumentError)
    end

    it "should convert required true to required" do
      lambda {
        @meta.attribute("db/mysql/databases", :required => true)
      }.should_not raise_error(ArgumentError)
      #attrib = @meta.attributes["db/mysql/databases"][:required].should == "required"
    end
    
    it "should convert required false to optional" do
      lambda {
        @meta.attribute("db/mysql/databases", :required => false)
      }.should_not raise_error(ArgumentError)
      #attrib = @meta.attributes["db/mysql/databases"][:required].should == "optional"
    end

    it "should set required to 'optional' by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:required].should == 'optional'
    end
  
    it "should make sure recipes is an array" do
      lambda {
        @meta.attribute("db/mysql/databases", :recipes => [])
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => Hash.new)
      }.should raise_error(ArgumentError)
    end

    it "should set recipes to an empty array by default" do
      @meta.attribute("db/mysql/databases", {})
      @meta.attributes["db/mysql/databases"][:recipes].should == [] 
    end

    it "should allow the default value to be a string, array, or hash" do
      lambda {
        @meta.attribute("db/mysql/databases", :default => [])
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :default => {})
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :default => "alice in chains")
      }.should_not raise_error(ArgumentError)
      lambda {
        @meta.attribute("db/mysql/databases", :required => :not_gonna_do_it)
      }.should raise_error(ArgumentError)
    end

    it "should error if default used with calculated" do
      lambda {
        attrs = {
          :calculated => true,
          :default => [ "I thought you said calculated" ]
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
      lambda {
        attrs = {
          :calculated => true,
          :default => "I thought you said calculated"
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
    end

    it "should allow a default that is a choice" do
      lambda {
        attrs = {
          :choice => [ "a", "b", "c"],
          :default => "b" 
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should_not raise_error(ArgumentError)
      lambda {
        attrs = {
          :choice => [ "a", "b", "c", "d", "e"],
          :default => ["b", "d"] 
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should_not raise_error(ArgumentError)
     end

    it "should error if default is not a choice" do
      lambda {
        attrs = {
          :choice => [ "a", "b", "c"],
          :default => "d" 
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
      lambda {
        attrs = {
          :choice => [ "a", "b", "c", "d", "e"],
          :default => ["b", "z"]
        }
        @meta.attribute("db/mysql/databases", attrs)
      }.should raise_error(ArgumentError)
    end
  end

  describe "recipes" do
    before(:each) do 
      @cookbook.recipe_files = [ "default.rb", "enlighten.rb" ]
      @meta = Chef::Cookbook::Metadata.new(@cookbook)
    end
    
    it "should have the names of the recipes" do
      @meta.recipes["test_cookbook"].should == ""
      @meta.recipes["test_cookbook::enlighten"].should == ""
    end

    it "should let you set the description for a recipe" do
      @meta.recipe "test_cookbook", "It, um... tests stuff?"
      @meta.recipes["test_cookbook"].should == "It, um... tests stuff?"
    end

    it "should automatically provide each recipe" do
      @meta.providing.has_key?("test_cookbook").should == true
      @meta.providing.has_key?("test_cookbook::enlighten").should == true
    end

  end

  describe "json" do
    before(:each) do 
      @cookbook.recipe_files = [ "default.rb", "enlighten.rb" ]
      @meta = Chef::Cookbook::Metadata.new(@cookbook)
      @meta.version "1.0"
      @meta.maintainer "Bobo T. Clown"
      @meta.maintainer_email "bobo@example.com"
      @meta.long_description "I have a long arm!"
      @meta.supports :ubuntu, "> 8.04"
      @meta.depends "bobo", "= 1.0"
      @meta.depends "bobotclown", "= 1.1"
      @meta.recommends "snark", "< 3.0"
      @meta.suggests "kindness", "> 2.0"
      @meta.conflicts "hatred"
      @meta.provides "foo(:bar, :baz)"
      @meta.replaces "snarkitron"
      @meta.recipe "test_cookbook::enlighten", "is your buddy"
      @meta.attribute "bizspark/has_login", 
        :display_name => "You have nothing" 
      @meta.version "1.2.3"
    end

    describe "serialize" do
      before(:each) do
        @serial = Chef::JSONCompat.from_json(@meta.to_json)
      end

      it "should serialize to a json hash" do
        Chef::JSONCompat.from_json(@meta.to_json).should be_a_kind_of(Hash)
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
          @serial[t].should == @meta.send(t.to_sym)
        end
      end
    end

    describe "deserialize" do
      before(:each) do
        @deserial = Chef::Cookbook::Metadata.from_json(@meta.to_json)
      end

      it "should deserialize to a Chef::Cookbook::Metadata object" do
        @deserial.should be_a_kind_of(Chef::Cookbook::Metadata)
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
          @deserial.send(t.to_sym).should == @meta.send(t.to_sym)
        end
      end
    end

    describe "from_hash" do
      before(:each) do
        @hash = @meta.to_hash
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
