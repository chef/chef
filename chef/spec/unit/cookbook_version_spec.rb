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

require 'spec_helper'

describe Chef::MinimalCookbookVersion do
  describe "when first created" do
    before do
      @params = { "id"=>"1a806f1c-b409-4d8e-abab-fa414ff5b96d",
                  "key"=>"activemq",
                  "value"=>{"version"=>"0.3.3", "deps"=>{"java"=>">= 0.0.0", "runit"=>">= 0.0.0"}}}
      @minimal_cookbook_version = Chef::MinimalCookbookVersion.new(@params)
    end

    it "has a name" do
      @minimal_cookbook_version.name.should == 'activemq'
    end

    it "has a version" do
      @minimal_cookbook_version.version.should == '0.3.3'
    end

    it "has a list of dependencies" do
      @minimal_cookbook_version.deps.should == {"java" => ">= 0.0.0", "runit" => ">= 0.0.0"}
    end

    it "has cookbook metadata" do
      metadata = @minimal_cookbook_version.metadata

      metadata.name.should == 'activemq'
      metadata.dependencies['java'].should == '>= 0.0.0'
      metadata.dependencies['runit'].should == '>= 0.0.0'
    end
  end

  describe "when created from cookbooks with old style version contraints" do
    before do
      @params = { "id"=>"1a806f1c-b409-4d8e-abab-fa414ff5b96d",
                  "key"=>"activemq",
                  "value"=>{"version"=>"0.3.3", "deps"=>{"apt" => ">> 1.0.0"}}}
      @minimal_cookbook_version = Chef::MinimalCookbookVersion.new(@params)
    end

    it "translates the version constraints" do
      metadata = @minimal_cookbook_version.metadata
      metadata.dependencies['apt'].should == '> 1.0.0'
    end
  end
end

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

    it "is not frozen" do
      @cookbook_version.should_not be_frozen_version
    end

    it "can be frozen" do
      @cookbook_version.freeze_version
      @cookbook_version.should be_frozen_version
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

    describe "raises an error when attempting to load a missing cookbook_file and" do
      before do
        node = Chef::Node.new.tap {|n| n.name("sample.node"); n[:fqdn] = "sample.example.com"; n[:platform] = "ubuntu"; n[:platform_version] = "10.04"}
        @attempt_to_load_file = lambda { @cookbook_version.preferred_manifest_record(node, :files, "no-such-thing.txt") }
      end

      it "describes the cookbook and version" do
        useful_explanation = Regexp.new(Regexp.escape("Cookbook 'tatft' (0.0.0) does not contain"))
        @attempt_to_load_file.should raise_error(Chef::Exceptions::FileNotFound, useful_explanation)
      end
  
      it "lists suggested places to look" do
        useful_explanation = Regexp.new(Regexp.escape("files/default/no-such-thing.txt"))
        @attempt_to_load_file.should raise_error(Chef::Exceptions::FileNotFound, useful_explanation)
      end
    end

  end

  describe "when cleaning up unused cookbook components" do
    before do
      Chef::CookbookVersion.reset_cache_validity
    end

    it "removes all files that belong to unused cookbooks" do
      file_cache = mock("Chef::FileCache with files from unused cookbooks")
      valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      obsolete_cb_files = %w{cookbooks/old1/recipes/default.rb cookbooks/old2/recipes/default.rb}
      file_cache.should_receive(:find).with(File.join(%w{cookbooks ** *})).and_return(valid_cached_cb_files + obsolete_cb_files)
      file_cache.should_receive(:delete).with('cookbooks/old1/recipes/default.rb')
      file_cache.should_receive(:delete).with('cookbooks/old2/recipes/default.rb')
      cookbook_hash = {"valid1"=> {}, "valid2" => {}}
      Chef::CookbookVersion.stub!(:cache).and_return(file_cache)
      Chef::CookbookVersion.clear_obsoleted_cookbooks(cookbook_hash)
    end

    it "removes all files not validated during the chef run" do
      file_cache = mock("Chef::FileCache with files from unused cookbooks")
      unused_template_files = %w{cookbooks/unused/templates/default/foo.conf.erb cookbooks/unused/tempaltes/default/bar.conf.erb}
      valid_cached_cb_files = %w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb}
      Chef::CookbookVersion.valid_cache_entries['cookbooks/valid1/recipes/default.rb'] = true
      Chef::CookbookVersion.valid_cache_entries['cookbooks/valid2/recipes/default.rb'] = true
      file_cache.should_receive(:find).with(File.join(%w{cookbooks ** *})).and_return(valid_cached_cb_files + unused_template_files)
      file_cache.should_receive(:delete).with('cookbooks/unused/templates/default/foo.conf.erb')
      file_cache.should_receive(:delete).with('cookbooks/unused/tempaltes/default/bar.conf.erb')
      cookbook_hash = {"valid1"=> {}, "valid2" => {}}
      Chef::CookbookVersion.stub!(:cache).and_return(file_cache)
      Chef::CookbookVersion.cleanup_file_cache
    end

    describe "on chef-solo" do
      before do
        Chef::Config[:solo] = true
      end

      after do
        Chef::Config[:solo] = false
      end

      it "does not remove anything" do
        Chef::CookbookVersion.cache.stub!(:find).and_return(%w{cookbooks/valid1/recipes/default.rb cookbooks/valid2/recipes/default.rb})
        Chef::CookbookVersion.cache.should_not_receive(:delete)
        Chef::CookbookVersion.cleanup_file_cache
      end

    end

  end

  describe "<=>" do

    it "should sort based on the version number" do
      examples = [
                  # smaller, larger
                  ["1.0", "2.0"],
                  ["1.2.3", "1.2.4"],
                  ["1.2.3", "1.3.0"],
                  ["1.2.3", "1.3"],
                  ["1.2.3", "2.1.1"],
                  ["1.2.3", "2.1"],
                  ["1.2", "1.2.4"],
                  ["1.2", "1.3.0"],
                  ["1.2", "1.3"],
                  ["1.2", "2.1.1"],
                  ["1.2", "2.1"]
                 ]
      examples.each do |smaller, larger|
        sm = Chef::CookbookVersion.new("foo")
        lg = Chef::CookbookVersion.new("foo")
        sm.version = smaller
        lg.version = larger
        sm.should be < lg
        lg.should be > sm
        sm.should_not == lg
      end
    end

    it "should equate versions 1.2 and 1.2.0" do
      a = Chef::CookbookVersion.new("foo")
      b = Chef::CookbookVersion.new("foo")
      a.version = "1.2"
      b.version = "1.2.0"
      a.should == b
    end
    

    it "should not allow you to sort cookbooks with different names" do
      apt = Chef::CookbookVersion.new "apt"
      apt.version = "1.0"
      god = Chef::CookbookVersion.new "god"
      god.version = "2.0"
      lambda {apt <=> god}.should raise_error(Chef::Exceptions::CookbookVersionNameMismatch)
    end
  end

  describe "when you set a version" do
    before do
      @cbv = Chef::CookbookVersion.new("version validation")
    end
    it "should accept valid cookbook versions" do
      good_versions = %w(1.2 1.2.3 1000.80.50000 0.300.25)
      good_versions.each do |v|
        @cbv.version = v
      end
    end

    it "should raise InvalidVersion for bad cookbook versions" do
      bad_versions = ["1.2.3.4", "1.2.a4", "1", "a", "1.2 3", "1.2 a",
                      "1 2 3", "1-2-3", "1_2_3", "1.2_3", "1.2-3"]
      the_error = Chef::Exceptions::InvalidCookbookVersion
      bad_versions.each do |v|
        lambda {@cbv.version = v}.should raise_error(the_error)
      end
    end

  end

  describe "when deleting in the database" do
    before do
      @couchdb_driver = Chef::CouchDB.new
      @cookbook_version = Chef::CookbookVersion.new("tatft", @couchdb_driver)
      @cookbook_version.version = "1.2.3"
      @couchdb_rev = "_123456789"
      @cookbook_version.couchdb_rev = @couchdb_rev
    end

    it "deletes its document from couchdb" do
      @couchdb_driver.should_receive(:delete).with("cookbook_version", "tatft-1.2.3", @couchdb_rev)
      @cookbook_version.cdb_destroy
    end

    it "deletes associated checksum objects when purged" do
      checksums = {"12345" => "/tmp/foo", "23456" => "/tmp/bar", "34567" => "/tmp/baz"}
      @cookbook_version.stub!(:checksums).and_return(checksums)

      chksum_docs = checksums.map do |md5, path|
        cksum_doc = mock("Chef::Checksum for #{md5} at #{path}")
        Chef::Checksum.should_receive(:cdb_load).with(md5, @couchdb_driver).and_return(cksum_doc)
        cksum_doc.should_receive(:purge)
        cksum_doc
      end

      @cookbook_version.should_receive(:cdb_destroy)
      @cookbook_version.purge
    end

    it "successfully purges when associated checksum objects are missing" do
      checksums = {"12345" => "/tmp/foo", "23456" => "/tmp/bar", "34567" => "/tmp/baz"}

      chksum_docs = checksums.map do |md5, path|
        cksum_doc = mock("Chef::Checksum for #{md5} at #{path}")
        Chef::Checksum.should_receive(:cdb_load).with(md5, @couchdb_driver).and_return(cksum_doc)
        cksum_doc.should_receive(:purge)
        cksum_doc
      end

      missing_checksum = {"99999" => "/tmp/qux"}
      Chef::Checksum.should_receive(:cdb_load).with("99999", @couchdb_driver).and_raise(Chef::Exceptions::CouchDBNotFound)

      @cookbook_version.stub!(:checksums).and_return(checksums.merge(missing_checksum))

      @cookbook_version.should_receive(:cdb_destroy)
      lambda {@cookbook_version.purge}.should_not raise_error
    end

  end

end
