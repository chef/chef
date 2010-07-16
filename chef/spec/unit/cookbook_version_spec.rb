#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Chef::CookbookVersion do
  describe "when first created" do
    before do
      @couchdb_driver = Chef::CouchDB.new
      @cookbook_version = Chef::CookbookVersion.new("tatft", @couchdb_driver)
    end

    it "has a name" do
      @cookbook_version.name.should == 'tatft'
    end

    it "has no attribute files" do
      @cookbook_version.attribute_filenames.should be_empty
    end

    it "has no resource definition files" do
      @cookbook_version.definition_filenames.should be_empty
    end

    it "has no cookbook files" do
      @cookbook_version.file_filenames.should be_empty
    end

    it "has no recipe files" do
      @cookbook_version.recipe_filenames.should be_empty
    end

    it "has no library files" do
      @cookbook_version.library_filenames.should be_empty
    end

    it "has no LWRP resource files" do
      @cookbook_version.resource_filenames.should be_empty
    end

    it "has no LWRP provider files" do
      @cookbook_version.provider_filenames.should be_empty
    end

    it "has no metadata files" do
      @cookbook_version.metadata_filenames.should be_empty
    end

    it "has no couchdb id" do
      @cookbook_version.couchdb_id.should be_nil
    end

    it "has the couchdb driver it was given on create" do
      @cookbook_version.couchdb.should equal(@couchdb_driver)
    end

    it "is \"ready\"" do
      # WTF is this? what are the valid states? and why aren't they set with encapsulating methods?
      # [Dan 15-Jul-2010]
      @cookbook_version.status.should == :ready
    end

    it "has empty metadata" do
      @cookbook_version.metadata.should == Chef::Cookbook::Metadata.new
    end

    it "creates a manifest hash of its contents" do
      expected = {"recipes"=>[], 
                  "definitions"=>[], 
                  "libraries"=>[], 
                  "attributes"=>[], 
                  "files"=>[], 
                  "templates"=>[], 
                  "resources"=>[], 
                  "providers"=>[], 
                  "root_files"=>[], 
                  "cookbook_name"=>"tatft", 
                  "metadata"=>Chef::Cookbook::Metadata.new,
                  "version"=>"0.0.0", 
                  "name"=>"tatft-0.0.0"} 
      @cookbook_version.manifest.should == expected
    end
  end

  describe "after the cookbook has been loaded" do
    MD5 = /[0-9a-f]{32}/

    before do
      # Currently the cookbook loader finds all the files then tells CookbookVersion
      # where they are.
      @cookbook_version = Chef::CookbookVersion.new("tatft")

      @cookbook = Hash.new { |hash, key| hash[key] = [] }

      cookbook_root = File.join(CHEF_SPEC_DATA, 'cb_version_cookbooks', 'tatft')

      # Dunno if the paths here are representitive of what is set by CookbookLoader...
      @cookbook[:attribute_filenames]   = Dir[File.join(cookbook_root, 'attributes', '**', '*.rb')]
      @cookbook[:definition_filenames]  = Dir[File.join(cookbook_root, 'definitions', '**', '*.rb')]
      @cookbook[:file_filenames]        = Dir[File.join(cookbook_root, 'files', '**', '*.tgz')]
      @cookbook[:recipe_filenames]      = Dir[File.join(cookbook_root, 'recipes', '**', '*.rb')]
      @cookbook[:template_filenames]    = Dir[File.join(cookbook_root, 'templates', '**', '*.erb')]
      @cookbook[:library_filenames]     = Dir[File.join(cookbook_root, 'libraries', '**', '*.rb')]
      @cookbook[:resource_filenames]    = Dir[File.join(cookbook_root, 'resources', '**', '*.rb')]
      @cookbook[:provider_filenames]    = Dir[File.join(cookbook_root, 'providers', '**', '*.rb')]
      @cookbook[:root_filenames]        = Array(File.join(cookbook_root, 'README.rdoc'))
      @cookbook[:metadata_filenames]    = Array(File.join(cookbook_root, 'metadata.json'))

      @cookbook_version.attribute_filenames  = @cookbook[:attribute_filenames]
      @cookbook_version.definition_filenames = @cookbook[:definition_filenames]
      @cookbook_version.recipe_filenames     = @cookbook[:recipe_filenames]
      @cookbook_version.template_filenames   = @cookbook[:template_filenames]
      @cookbook_version.file_filenames       = @cookbook[:file_filenames]
      @cookbook_version.library_filenames    = @cookbook[:library_filenames]
      @cookbook_version.resource_filenames   = @cookbook[:resource_filenames]
      @cookbook_version.provider_filenames   = @cookbook[:provider_filenames]
      @cookbook_version.root_filenames       = @cookbook[:root_filenames]
      @cookbook_version.metadata_filenames   = @cookbook[:metadata_filenames]
    end

    it "generates a manifest containing the cookbook's files" do
      manifest = @cookbook_version.manifest

      manifest["metadata"].should == Chef::Cookbook::Metadata.new
      manifest["cookbook_name"].should == "tatft"

      manifest["recipes"].should have(1).recipe_file

      recipe = manifest["recipes"].first
      recipe["name"].should == "default.rb"
      recipe["path"].should == "recipes/default.rb"
      recipe["checksum"].should match(MD5)
      recipe["specificity"].should == "default"

      manifest["definitions"].should have(1).definition_file

      definition = manifest["definitions"].first
      definition["name"].should == "runit_service.rb"
      definition["path"].should == "definitions/runit_service.rb"
      definition["checksum"].should match(MD5)
      definition["specificity"].should == "default"

      manifest["libraries"].should have(1).library_file

      library = manifest["libraries"].first
      library["name"].should == "ownage.rb"
      library["path"].should == "libraries/ownage.rb"
      library["checksum"].should match(MD5)
      library["specificity"].should == "default"

      manifest["attributes"].should have(1).attribute_file

      attribute_file = manifest["attributes"].first
      attribute_file["name"].should == "default.rb"
      attribute_file["path"].should == "attributes/default.rb"
      attribute_file["checksum"].should match(MD5)
      attribute_file["specificity"].should == "default"

      manifest["files"].should have(1).cookbook_file

      cookbook_file = manifest["files"].first
      cookbook_file["name"].should == "giant_blob.tgz"
      cookbook_file["path"].should == "files/default/giant_blob.tgz"
      cookbook_file["checksum"].should match(MD5)
      cookbook_file["specificity"].should == "default"

      manifest["templates"].should have(1).template

      template = manifest["templates"].first
      template["name"].should == "configuration.erb"
      template["path"].should == "templates/default/configuration.erb"
      template["checksum"].should match(MD5)
      template["specificity"].should == "default"

      manifest["resources"].should have(1).lwr

      lwr = manifest["resources"].first
      lwr["name"].should == "lwr.rb"
      lwr["path"].should == "resources/lwr.rb"
      lwr["checksum"].should match(MD5)
      lwr["specificity"].should == "default"

      manifest["providers"].should have(1).lwp

      lwp = manifest["providers"].first
      lwp["name"].should == "lwp.rb"
      lwp["path"].should == "providers/lwp.rb"
      lwp["checksum"].should match(MD5)
      lwp["specificity"].should == "default"

      manifest["root_files"].should have(1).file_in_the_cookbook_root

      readme = manifest["root_files"].first
      readme["name"].should == "README.rdoc"
      readme["path"].should == "README.rdoc"
      readme["checksum"].should match(MD5)
      readme["specificity"].should == "default"
    end

  end



end