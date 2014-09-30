#
# Author:: Daniel DeLeo (<dan@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

describe Chef::Cookbook::CookbookVersionLoader do
  before do
    Chef::Platform.stub(:windows?) { false }
  end

  describe "loading a cookbook" do

    let(:chefignore) { nil }

    let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "cookbooks/openldap") }

    let(:cookbook_loader) { Chef::Cookbook::CookbookVersionLoader.new(cookbook_path, chefignore) }

    let(:loaded_cookbook) do
      cookbook_loader.load!
      cookbook_loader.cookbook_version
    end

    def full_path(cookbook_relative_path)
      File.join(cookbook_path, cookbook_relative_path)
    end

    it "loads attribute files of the cookbook" do
      expect(loaded_cookbook.attribute_filenames).to include(full_path("/attributes/default.rb"))
      expect(loaded_cookbook.attribute_filenames).to include(full_path("/attributes/smokey.rb"))
    end

    it "loads definition files" do
      expect(loaded_cookbook.definition_filenames).to include(full_path("/definitions/client.rb"))
      expect(loaded_cookbook.definition_filenames).to include(full_path("/definitions/server.rb"))
    end

    it "loads recipes" do
      expect(loaded_cookbook.recipe_filenames).to include(full_path("/recipes/default.rb"))
      expect(loaded_cookbook.recipe_filenames).to include(full_path("/recipes/gigantor.rb"))
      expect(loaded_cookbook.recipe_filenames).to include(full_path("/recipes/one.rb"))
      expect(loaded_cookbook.recipe_filenames).to include(full_path("/recipes/return.rb"))
    end

    it "loads static files in the files/ dir" do
      expect(loaded_cookbook.file_filenames).to include(full_path("/files/default/remotedir/remotesubdir/remote_subdir_file1.txt"))
      expect(loaded_cookbook.file_filenames).to include(full_path("/files/default/remotedir/remotesubdir/remote_subdir_file2.txt"))
    end

    it "loads files that start with a ." do
      expect(loaded_cookbook.file_filenames).to include(full_path("/files/default/.dotfile"))
      expect(loaded_cookbook.file_filenames).to include(full_path("/files/default/.ssh/id_rsa"))
      expect(loaded_cookbook.file_filenames).to include(full_path("/files/default/remotedir/.a_dotdir/.a_dotfile_in_a_dotdir"))
    end

    it "should load the metadata for the cookbook" do
      loaded_cookbook.metadata.name.to_s.should == "openldap"
      loaded_cookbook.metadata.should be_a_kind_of(Chef::Cookbook::Metadata)
    end

    context "when a cookbook has ignored files" do

      let(:chefignore) { Chef::Cookbook::Chefignore.new(File.join(CHEF_SPEC_DATA, "cookbooks")) }

      let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "kitchen/openldap") }

      it "skips ignored files" do
        expect(loaded_cookbook.recipe_filenames).to include(full_path("recipes/gigantor.rb"))
        expect(loaded_cookbook.recipe_filenames).to include(full_path("recipes/woot.rb"))
        expect(loaded_cookbook.recipe_filenames).to_not include(full_path("recipes/ignoreme.rb"))
      end

    end

    context "when the given path is not actually a cookbook" do

      let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "cookbooks/NOTHING_HERE_FOLKS") }

      it "raises an error when loading with #load!" do
        expect { cookbook_loader.load! }.to raise_error(Chef::Exceptions::CookbookNotFoundInRepo)
      end

      it "skips the cookbook when called with #load" do
        expect { cookbook_loader.load }.to_not raise_error
      end

    end

    context "when a cookbook has a metadata name different than directory basename" do

      let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "cookbooks/name-mismatch-versionnumber") }

      it "prefers the metadata name to the directory basename" do
        expect(loaded_cookbook.name).to eq(:"name-mismatch")
      end

    end

    context "when a cookbook has a metadata file with a ruby error [CHEF-2923]" do

      let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "invalid-metadata-chef-repo/invalid-metadata") }

      it "raises an error when loading with #load!" do
        expect { cookbook_loader.load! }.to raise_error("THIS METADATA HAS A BUG")
      end

      it "raises an error when called with #load" do
        expect { cookbook_loader.load }.to raise_error("THIS METADATA HAS A BUG")
      end

      it "doesn't raise an error when determining the cookbook name" do
        expect { cookbook_loader.cookbook_name }.to_not raise_error
      end

      it "doesn't raise an error when metadata is first generated" do
        expect { cookbook_loader.metadata }.to_not raise_error
      end

      it "sets an error flag containing error information" do
        cookbook_loader.metadata
        expect(cookbook_loader.metadata_error).to be_a(StandardError)
        expect(cookbook_loader.metadata_error.message).to eq("THIS METADATA HAS A BUG")
      end

    end

    context "when a cookbook has a metadata file with invalid metadata" do

      let(:cookbook_path) { File.join(CHEF_SPEC_DATA, "incomplete-metadata-chef-repo/incomplete-metadata") }

      let(:error_message) do
        "Cookbook loaded at path(s) [#{cookbook_path}] has invalid metadata: The `name' attribute is required in cookbook metadata"
      end

      it "raises an error when loading with #load!" do
        expect { cookbook_loader.load! }.to raise_error(Chef::Exceptions::MetadataNotValid, error_message)
      end

      it "raises an error when called with #load" do
        expect { cookbook_loader.load }.to raise_error(Chef::Exceptions::MetadataNotValid, error_message)
      end

      it "uses the inferred cookbook name [CHEF-2923]" do
        # This behavior is intended to support the CHEF-2923 feature where
        # invalid metadata doesn't prevent you from uploading other cookbooks.
        #
        # The metadata is the definitive source of the cookbook name, but if
        # the metadata is incomplete/invalid, we can't read the name from it.
        #
        # The CookbookLoader stores CookbookVersionLoaders in a Hash with
        # cookbook names as the keys, and finds the loader in this Hash to call
        # #load on it when the user runs a command like `knife cookbook upload specific-cookbook`
        #
        # Most of the time this will work, but if the user tries to upload a
        # specific cookbook by name, has customized that cookbook's name (so it
        # doesn't match the inferred name), and that metadata file has a syntax
        # error, we might report a "cookbook not found" error instead of the
        # metadata syntax error that is the actual cause.
        expect(cookbook_loader.cookbook_name).to eq(:"incomplete-metadata")
      end

    end

  end

end

