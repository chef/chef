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

describe Chef::CookbookLoader do
  before(:each) do
    @repo_paths = [ File.expand_path(File.join(CHEF_SPEC_DATA, "kitchen")),
                    File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks")) ]
    @cookbook_loader = Chef::CookbookLoader.new(@repo_paths)
  end

  describe "loading all cookbooks" do
    before(:each) do
      @cookbook_loader.load_cookbooks
    end

    describe "[]" do
      it "should return cookbook objects with []" do
        @cookbook_loader[:openldap].should be_a_kind_of(Chef::CookbookVersion)
      end

      it "should raise an exception if it cannot find a cookbook with []" do
        lambda { @cookbook_loader[:monkeypoop] }.should raise_error(Chef::Exceptions::CookbookNotFoundInRepo)
      end

      it "should allow you to look up available cookbooks with [] and a symbol" do
        @cookbook_loader[:openldap].name.should eql(:openldap)
      end

      it "should allow you to look up available cookbooks with [] and a string" do
        @cookbook_loader["openldap"].name.should eql(:openldap)
      end
    end

    describe "each" do
      it "should allow you to iterate over cookbooks with each" do
        seen = Hash.new
        @cookbook_loader.each do |cookbook_name, cookbook|
          seen[cookbook_name] = true
        end
        seen.should have_key("openldap")
        seen.should have_key("apache2")
      end

      it "should iterate in alphabetical order" do
        seen = Array.new
        @cookbook_loader.each do |cookbook_name, cookbook|
          seen << cookbook_name
          end
        seen[0].should == "angrybash"
        seen[1].should == "apache2"
        seen[2].should == "borken"
        seen[3].should == "java"
        seen[4].should == "openldap"
      end
    end
  
    describe "load_cookbooks" do
      it "should find all the cookbooks in the cookbook path" do
        Chef::Config.cookbook_path << File.expand_path(File.join(CHEF_SPEC_DATA, "hidden-cookbooks"))
        @cookbook_loader.load_cookbooks
        @cookbook_loader.should have_key(:openldap)
        @cookbook_loader.should have_key(:apache2)
      end
  
      it "should allow you to override an attribute file via cookbook_path" do
        @cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/attributes\/default.rb/
        }.should_not eql(nil)
        @cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /kitchen\/openldap\/attributes\/default.rb/
        }.should eql(nil)
      end
  
      it "should load different attribute files from deeper paths" do
        @cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /kitchen\/openldap\/attributes\/robinson.rb/
        }.should_not eql(nil)
      end
  
      it "should allow you to override a definition file via cookbook_path" do
        @cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/definitions\/client.rb/
        }.should_not eql(nil)
        @cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /kitchen\/openldap\/definitions\/client.rb/
        }.should eql(nil)
      end
  
      it "should load definition files from deeper paths" do
        @cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /kitchen\/openldap\/definitions\/drewbarrymore.rb/
        }.should_not eql(nil)
      end
  
      it "should allow you to override a recipe file via cookbook_path" do
        @cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/recipes\/gigantor.rb/
        }.should_not eql(nil)
        @cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/gigantor.rb/
        }.should eql(nil)
      end
  
      it "should load recipe files from deeper paths" do
        @cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/woot.rb/
        }.should_not eql(nil)
      end
  
      it "should allow you to have an 'ignore' file, which skips loading files in later cookbooks" do
        @cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/ignoreme.rb/
        }.should eql(nil)
      end
  
      it "should find files that start with a ." do
        @cookbook_loader[:openldap].file_filenames.detect { |f|
          f =~ /\.dotfile$/
        }.should =~ /\.dotfile$/
        @cookbook_loader[:openldap].file_filenames.detect { |f|
          f =~ /\.ssh\/id_rsa$/
        }.should =~ /\.ssh\/id_rsa$/
      end
  
      it "should load the metadata for the cookbook" do
        @cookbook_loader.metadata[:openldap].name.should == :openldap
        @cookbook_loader.metadata[:openldap].should be_a_kind_of(Chef::Cookbook::Metadata)
      end

      it "should check each cookbook directory only once (CHEF-3487)" do
        cookbooks = []
        @repo_paths.each do |repo_path|
          cookbooks |= Dir[File.join(repo_path, "*")]
        end
        cookbooks.each do |cookbook|
            File.should_receive(:directory?).with(cookbook).once;
        end
        @cookbook_loader.load_cookbooks
      end
    end # load_cookbooks

  end # loading all cookbooks

  describe "loading only one cookbook" do
    before(:each) do
      @cookbook_loader = Chef::CookbookLoader.new(@repo_paths)
      @cookbook_loader.load_cookbook("openldap")
    end

    it "should have loaded the correct cookbook" do
      seen = Hash.new
      @cookbook_loader.each do |cookbook_name, cookbook|
        seen[cookbook_name] = true
      end
      seen.should have_key("openldap")
    end

    it "should not load the cookbook again when accessed" do
      @cookbook_loader.should_not_receive('load_cookbook')
      @cookbook_loader["openldap"]
    end

    it "should not load the other cookbooks" do
      seen = Hash.new
      @cookbook_loader.each do |cookbook_name, cookbook|
        seen[cookbook_name] = true
      end
      seen.should_not have_key("apache2")
    end

    it "should load another cookbook lazily with []" do
      @cookbook_loader["apache2"].should be_a_kind_of(Chef::CookbookVersion)
    end

    describe "loading all cookbooks after loading only one cookbook" do
      before(:each) do
        @cookbook_loader.load_cookbooks
      end

      it "should load all cookbooks" do
        seen = Hash.new
        @cookbook_loader.each do |cookbook_name, cookbook|
          seen[cookbook_name] = true
        end
        seen.should have_key("openldap")
        seen.should have_key("apache2")
      end   
    end
  end # loading only one cookbook
end
