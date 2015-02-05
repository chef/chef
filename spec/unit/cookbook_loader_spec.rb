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
  before do
    allow(Chef::Platform).to receive(:windows?) {false}
  end
  let(:repo_paths) do
    [
      File.expand_path(File.join(CHEF_SPEC_DATA, "kitchen")),
      File.expand_path(File.join(CHEF_SPEC_DATA, "cookbooks"))
    ]
  end

  let(:cookbook_loader) { Chef::CookbookLoader.new(repo_paths) }

  it "checks each directory only once when loading (CHEF-3487)" do
    cookbook_paths = []
    repo_paths.each do |repo_path|
      cookbook_paths |= Dir[File.join(repo_path, "*")]
    end

    cookbook_paths.delete_if { |path| File.basename(path) == "chefignore" }

    cookbook_paths.each do |cookbook_path|
      expect(Chef::Cookbook::CookbookVersionLoader).to receive(:new).
        with(cookbook_path, anything).
        once.
        and_call_original
    end
    cookbook_loader.load_cookbooks
  end


  context "after loading all cookbooks" do
    before(:each) do
      cookbook_loader.load_cookbooks
    end

    describe "[]" do
      it "should return cookbook objects with []" do
        expect(cookbook_loader[:openldap]).to be_a_kind_of(Chef::CookbookVersion)
      end

      it "should raise an exception if it cannot find a cookbook with []" do
        expect { cookbook_loader[:monkeypoop] }.to raise_error(Chef::Exceptions::CookbookNotFoundInRepo)
      end

      it "should allow you to look up available cookbooks with [] and a symbol" do
        expect(cookbook_loader[:openldap].name).to eql(:openldap)
      end

      it "should allow you to look up available cookbooks with [] and a string" do
        expect(cookbook_loader["openldap"].name).to eql(:openldap)
      end
    end

    describe "each" do
      it "should allow you to iterate over cookbooks with each" do
        seen = Hash.new
        cookbook_loader.each do |cookbook_name, cookbook|
          seen[cookbook_name] = true
        end
        expect(seen).to have_key("openldap")
        expect(seen).to have_key("apache2")
      end

      it "should iterate in alphabetical order" do
        seen = Array.new
        cookbook_loader.each do |cookbook_name, cookbook|
          seen << cookbook_name
          end
        expect(seen[0]).to eq("angrybash")
        expect(seen[1]).to eq("apache2")
        expect(seen[2]).to eq("borken")
        expect(seen[3]).to eq("ignorken")
        expect(seen[4]).to eq("java")
        expect(seen[5]).to eq("name-mismatch")
        expect(seen[6]).to eq("openldap")
      end
    end

    describe "referencing cookbook files" do
      it "should find all the cookbooks in the cookbook path" do
        cookbook_loader.load_cookbooks
        expect(cookbook_loader).to have_key(:openldap)
        expect(cookbook_loader).to have_key(:apache2)
      end

      it "should allow you to override an attribute file via cookbook_path" do
        expect(cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/attributes\/default.rb/
        }).not_to eql(nil)
        expect(cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /kitchen\/openldap\/attributes\/default.rb/
        }).to eql(nil)
      end

      it "should load different attribute files from deeper paths" do
        expect(cookbook_loader[:openldap].attribute_filenames.detect { |f|
          f =~ /kitchen\/openldap\/attributes\/robinson.rb/
        }).not_to eql(nil)
      end

      it "should allow you to override a definition file via cookbook_path" do
        expect(cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/definitions\/client.rb/
        }).not_to eql(nil)
        expect(cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /kitchen\/openldap\/definitions\/client.rb/
        }).to eql(nil)
      end

      it "should load definition files from deeper paths" do
        expect(cookbook_loader[:openldap].definition_filenames.detect { |f|
          f =~ /kitchen\/openldap\/definitions\/drewbarrymore.rb/
        }).not_to eql(nil)
      end

      it "should allow you to override a recipe file via cookbook_path" do
        expect(cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /cookbooks\/openldap\/recipes\/gigantor.rb/
        }).not_to eql(nil)
        expect(cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/gigantor.rb/
        }).to eql(nil)
      end

      it "should load recipe files from deeper paths" do
        expect(cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/woot.rb/
        }).not_to eql(nil)
      end

      it "should allow you to have an 'ignore' file, which skips loading files in later cookbooks" do
        expect(cookbook_loader[:openldap].recipe_filenames.detect { |f|
          f =~ /kitchen\/openldap\/recipes\/ignoreme.rb/
        }).to eql(nil)
      end

      it "should find files that start with a ." do
        expect(cookbook_loader[:openldap].file_filenames.detect { |f|
          f =~ /\.dotfile$/
        }).to match(/\.dotfile$/)
        expect(cookbook_loader[:openldap].file_filenames.detect { |f|
          f =~ /\.ssh\/id_rsa$/
        }).to match(/\.ssh\/id_rsa$/)
      end

      it "should load the metadata for the cookbook" do
        expect(cookbook_loader.metadata[:openldap].name.to_s).to eq("openldap")
        expect(cookbook_loader.metadata[:openldap]).to be_a_kind_of(Chef::Cookbook::Metadata)
      end

    end # referencing cookbook files

  end # loading all cookbooks

  context "loading all cookbooks when one has invalid metadata" do

    let(:repo_paths) do
      [
        File.join(CHEF_SPEC_DATA, "kitchen"),
        File.join(CHEF_SPEC_DATA, "cookbooks"),
        File.join(CHEF_SPEC_DATA, "invalid-metadata-chef-repo")
      ]
    end

    it "does not squelch the exception" do
      expect { cookbook_loader.load_cookbooks }.to raise_error("THIS METADATA HAS A BUG")
    end

  end

  describe "loading only one cookbook" do
    before(:each) do
      cookbook_loader.load_cookbook("openldap")
    end

    it "should have loaded the correct cookbook" do
      seen = Hash.new
      cookbook_loader.each do |cookbook_name, cookbook|
        seen[cookbook_name] = true
      end
      expect(seen).to have_key("openldap")
    end

    it "should not duplicate keys when serialized to JSON" do
      # Chef JSON serialization will generate duplicate keys if given
      # a Hash containing matching string and symbol keys. See CHEF-4571.
      aa = cookbook_loader["openldap"]
      expect(aa.to_hash["metadata"].recipes.keys).not_to include(:openldap)
      expect(aa.to_hash["metadata"].recipes.keys).to include("openldap")
      expected_desc = "Main Open LDAP configuration"
      expect(aa.to_hash["metadata"].recipes["openldap"]).to eq(expected_desc)
      raw = Chef::JSONCompat.to_json(aa.to_hash["metadata"].recipes)
      search_str = "\"openldap\":\""
      key_idx = raw.index(search_str)
      expect(key_idx).to be > 0
      dup_idx = raw[(key_idx + 1)..-1].index(search_str)
      expect(dup_idx).to be_nil
    end

    it "should not load the cookbook again when accessed" do
      expect(cookbook_loader).not_to receive('load_cookbook')
      cookbook_loader["openldap"]
    end

    it "should not load the other cookbooks" do
      seen = Hash.new
      cookbook_loader.each do |cookbook_name, cookbook|
        seen[cookbook_name] = true
      end
      expect(seen).not_to have_key("apache2")
    end

    it "should load another cookbook lazily with []" do
      expect(cookbook_loader["apache2"]).to be_a_kind_of(Chef::CookbookVersion)
    end

    context "when an unrelated cookbook has invalid metadata" do

      let(:repo_paths) do
        [
          File.join(CHEF_SPEC_DATA, "kitchen"),
          File.join(CHEF_SPEC_DATA, "cookbooks"),
          File.join(CHEF_SPEC_DATA, "invalid-metadata-chef-repo")
        ]
      end

      it "ignores the invalid cookbook" do
        expect { cookbook_loader["openldap"] }.to_not raise_error
      end

      it "surfaces the exception if the cookbook is loaded later" do
        expect { cookbook_loader["invalid-metadata"] }.to raise_error("THIS METADATA HAS A BUG")
      end

    end

    describe "loading all cookbooks after loading only one cookbook" do
      before(:each) do
        cookbook_loader.load_cookbooks
      end

      it "should load all cookbooks" do
        seen = Hash.new
        cookbook_loader.each do |cookbook_name, cookbook|
          seen[cookbook_name] = true
        end
        expect(seen).to have_key("openldap")
        expect(seen).to have_key("apache2")
      end
    end
  end # loading only one cookbook

  describe "loading a single cookbook with a different name than basename" do

    before(:each) do
      cookbook_loader.load_cookbook("name-mismatch")
    end

    it "loads the correct cookbook" do
      cookbook_version = cookbook_loader["name-mismatch"]
      expect(cookbook_version).to be_a_kind_of(Chef::CookbookVersion)
      expect(cookbook_version.name).to eq(:"name-mismatch")
    end

  end
end
