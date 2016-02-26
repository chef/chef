#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require "spec_helper"

describe Chef::CookbookVersion do
  describe "when first created" do
    let(:cookbook_version) { Chef::CookbookVersion.new("tatft", "/tmp/blah") }

    it "has a name" do
      expect(cookbook_version.name).to eq("tatft")
    end

    it "has no attribute files" do
      expect(cookbook_version.attribute_filenames).to be_empty
    end

    it "has no resource definition files" do
      expect(cookbook_version.definition_filenames).to be_empty
    end

    it "has no cookbook files" do
      expect(cookbook_version.file_filenames).to be_empty
    end

    it "has no recipe files" do
      expect(cookbook_version.recipe_filenames).to be_empty
    end

    it "has no library files" do
      expect(cookbook_version.library_filenames).to be_empty
    end

    it "has no LWRP resource files" do
      expect(cookbook_version.resource_filenames).to be_empty
    end

    it "has no LWRP provider files" do
      expect(cookbook_version.provider_filenames).to be_empty
    end

    it "has no metadata files" do
      expect(cookbook_version.metadata_filenames).to be_empty
    end

    it "has an empty set of all_files" do
      expect(cookbook_version.all_files).to be_empty
    end

    it "is not frozen" do
      expect(cookbook_version).not_to be_frozen_version
    end

    it "can be frozen" do
      cookbook_version.freeze_version
      expect(cookbook_version).to be_frozen_version
    end

    it "has empty metadata" do
      expect(cookbook_version.metadata).to eq(Chef::Cookbook::Metadata.new)
    end

  end

  describe "with a cookbook directory named tatft" do
    MD5 = /[0-9a-f]{32}/

    let(:cookbook_paths_by_type) do
      {
        # Dunno if the paths here are representitive of what is set by CookbookLoader...
        all_files:  Dir[File.join(cookbook_root, "**", "*.rb")],
        attribute_filenames:  Dir[File.join(cookbook_root, "attributes", "**", "*.rb")],
        definition_filenames: Dir[File.join(cookbook_root, "definitions", "**", "*.rb")],
        file_filenames:       Dir[File.join(cookbook_root, "files", "**", "*.tgz")],
        recipe_filenames:     Dir[File.join(cookbook_root, "recipes", "**", "*.rb")],
        template_filenames:   Dir[File.join(cookbook_root, "templates", "**", "*.erb")],
        library_filenames:    Dir[File.join(cookbook_root, "libraries", "**", "*.rb")],
        resource_filenames:   Dir[File.join(cookbook_root, "resources", "**", "*.rb")],
        provider_filenames:   Dir[File.join(cookbook_root, "providers", "**", "*.rb")],
        root_filenames:       Array(File.join(cookbook_root, "README.rdoc")),
        metadata_filenames:   Array(File.join(cookbook_root, "metadata.json")),
      }
    end

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "tatft") }

    describe "and a cookbook with the same name" do

      let(:cookbook_version) do
        Chef::CookbookVersion.new("tatft", cookbook_root).tap do |c|
        # Currently the cookbook loader finds all the files then tells CookbookVersion
        # where they are.
          c.attribute_filenames  = cookbook_paths_by_type[:attribute_filenames]
          c.definition_filenames = cookbook_paths_by_type[:definition_filenames]
          c.recipe_filenames     = cookbook_paths_by_type[:recipe_filenames]
          c.template_filenames   = cookbook_paths_by_type[:template_filenames]
          c.file_filenames       = cookbook_paths_by_type[:file_filenames]
          c.library_filenames    = cookbook_paths_by_type[:library_filenames]
          c.resource_filenames   = cookbook_paths_by_type[:resource_filenames]
          c.provider_filenames   = cookbook_paths_by_type[:provider_filenames]
          c.root_filenames       = cookbook_paths_by_type[:root_filenames]
          c.metadata_filenames   = cookbook_paths_by_type[:metadata_filenames]
        end
      end

      # Used to test file-specificity related file lookups
      let(:node) do
        Chef::Node.new.tap do |n|
          n.set[:platform] = "ubuntu"
          n.set[:platform_version] = "13.04"
          n.name("testing")
        end
      end

      it "determines whether a template is available for a given node" do
        expect(cookbook_version).to have_template_for_node(node, "configuration.erb")
        expect(cookbook_version).not_to have_template_for_node(node, "missing.erb")
      end

      it "determines whether a cookbook_file is available for a given node" do
        expect(cookbook_version).to have_cookbook_file_for_node(node, "giant_blob.tgz")
        expect(cookbook_version).not_to have_cookbook_file_for_node(node, "missing.txt")
      end

      describe "raises an error when attempting to load a missing cookbook_file and" do
        let(:node) do
          Chef::Node.new.tap do |n|
            n.name("sample.node")
            n.automatic_attrs[:fqdn] = "sample.example.com"
            n.automatic_attrs[:platform] = "ubuntu"
            n.automatic_attrs[:platform_version] = "10.04"
          end
        end

        def attempt_to_load_file
          cookbook_version.preferred_manifest_record(node, :files, "no-such-thing.txt")
        end

        it "describes the cookbook and version" do
          useful_explanation = Regexp.new(Regexp.escape("Cookbook 'tatft' (0.0.0) does not contain"))
          expect { attempt_to_load_file }.to raise_error(Chef::Exceptions::FileNotFound, useful_explanation)
        end

        it "lists suggested places to look" do
          useful_explanation = Regexp.new(Regexp.escape("files/default/no-such-thing.txt"))
          expect { attempt_to_load_file }.to raise_error(Chef::Exceptions::FileNotFound, useful_explanation)
        end
      end
    end

  end

  describe "with a cookbook directory named cookbook2 that has unscoped files" do

    let(:cookbook_paths_by_type) do
      {
        # Dunno if the paths here are representitive of what is set by CookbookLoader...
        all_files:            Dir[File.join(cookbook_root, "**", "*.rb")],
        attribute_filenames:  Dir[File.join(cookbook_root, "attributes", "**", "*.rb")],
        definition_filenames: Dir[File.join(cookbook_root, "definitions", "**", "*.rb")],
        file_filenames:       Dir[File.join(cookbook_root, "files", "**", "*.*")],
        recipe_filenames:     Dir[File.join(cookbook_root, "recipes", "**", "*.rb")],
        template_filenames:   Dir[File.join(cookbook_root, "templates", "**", "*.*")],
        library_filenames:    Dir[File.join(cookbook_root, "libraries", "**", "*.rb")],
        resource_filenames:   Dir[File.join(cookbook_root, "resources", "**", "*.rb")],
        provider_filenames:   Dir[File.join(cookbook_root, "providers", "**", "*.rb")],
        root_filenames:       Array(File.join(cookbook_root, "README.rdoc")),
        metadata_filenames:   Array(File.join(cookbook_root, "metadata.json")),
      }
    end

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "cookbook2") }

    let(:cookbook_version) do
      Chef::CookbookVersion.new("cookbook2", cookbook_root).tap do |c|
        c.attribute_filenames  = cookbook_paths_by_type[:attribute_filenames]
        c.definition_filenames = cookbook_paths_by_type[:definition_filenames]
        c.recipe_filenames     = cookbook_paths_by_type[:recipe_filenames]
        c.template_filenames   = cookbook_paths_by_type[:template_filenames]
        c.file_filenames       = cookbook_paths_by_type[:file_filenames]
        c.library_filenames    = cookbook_paths_by_type[:library_filenames]
        c.resource_filenames   = cookbook_paths_by_type[:resource_filenames]
        c.provider_filenames   = cookbook_paths_by_type[:provider_filenames]
        c.root_filenames       = cookbook_paths_by_type[:root_filenames]
        c.metadata_filenames   = cookbook_paths_by_type[:metadata_filenames]
      end
    end

    # Used to test file-specificity related file lookups
    let(:node) do
      Chef::Node.new.tap do |n|
        n.set[:platform] = "ubuntu"
        n.set[:platform_version] = "13.04"
        n.name("testing")
      end
    end

    it "should see a template" do
      expect(cookbook_version).to have_template_for_node(node, "test.erb")
    end

    it "should see a template using an array lookup" do
      expect(cookbook_version).to have_template_for_node(node, ["test.erb"])
    end

    it "should see a template using an array lookup with non-existent elements" do
      expect(cookbook_version).to have_template_for_node(node, ["missing.txt", "test.erb"])
    end

    it "should see a file" do
      expect(cookbook_version).to have_cookbook_file_for_node(node, "test.txt")
    end

    it "should see a file using an array lookup" do
      expect(cookbook_version).to have_cookbook_file_for_node(node, ["test.txt"])
    end

    it "should see a file using an array lookup with non-existent elements" do
      expect(cookbook_version).to have_cookbook_file_for_node(node, ["missing.txt", "test.txt"])
    end

    it "should not see a non-existent template" do
      expect(cookbook_version).not_to have_template_for_node(node, "missing.erb")
    end

    it "should not see a non-existent template using an array lookup" do
      expect(cookbook_version).not_to have_template_for_node(node, ["missing.erb"])
    end

    it "should not see a non-existent file" do
      expect(cookbook_version).not_to have_cookbook_file_for_node(node, "missing.txt")
    end

    it "should not see a non-existent file using an array lookup" do
      expect(cookbook_version).not_to have_cookbook_file_for_node(node, ["missing.txt"])
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
                  ["1.2", "2.1"],
                 ]
      examples.each do |smaller, larger|
        sm = Chef::CookbookVersion.new("foo", "/tmp/blah")
        lg = Chef::CookbookVersion.new("foo", "/tmp/blah")
        sm.version = smaller
        lg.version = larger
        expect(sm).to be < lg
        expect(lg).to be > sm
        expect(sm).not_to eq(lg)
      end
    end

    it "should equate versions 1.2 and 1.2.0" do
      a = Chef::CookbookVersion.new("foo", "/tmp/blah")
      b = Chef::CookbookVersion.new("foo", "/tmp/blah")
      a.version = "1.2"
      b.version = "1.2.0"
      expect(a).to eq(b)
    end

    it "should not allow you to sort cookbooks with different names" do
      apt = Chef::CookbookVersion.new "apt", "/tmp/blah"
      apt.version = "1.0"
      god = Chef::CookbookVersion.new "god", "/tmp/blah"
      god.version = "2.0"
      expect { apt <=> god }.to raise_error(Chef::Exceptions::CookbookVersionNameMismatch)
    end
  end

  describe "when you set a version" do

    subject(:cbv) { Chef::CookbookVersion.new("version validation", "/tmp/blah") }

    it "should accept valid cookbook versions" do
      good_versions = %w{1.2 1.2.3 1000.80.50000 0.300.25}
      good_versions.each do |v|
        cbv.version = v
      end
    end

    it "should raise InvalidVersion for bad cookbook versions" do
      bad_versions = ["1.2.3.4", "1.2.a4", "1", "a", "1.2 3", "1.2 a",
                      "1 2 3", "1-2-3", "1_2_3", "1.2_3", "1.2-3"]
      the_error = Chef::Exceptions::InvalidCookbookVersion
      bad_versions.each do |v|
        expect { cbv.version = v }.to raise_error(the_error)
      end
    end

  end

  describe "when deprecation warnings are errors" do

    subject(:cbv) { Chef::CookbookVersion.new("version validation", "/tmp/blah") }

    it "errors on #status and #status=" do
      expect { cbv.status = :wat }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
      expect { cbv.status }.to raise_error(Chef::Exceptions::DeprecatedFeatureError)
    end

  end

  describe "deprecated features" do

    subject(:cbv) { Chef::CookbookVersion.new("tatft", "/tmp/blah").tap { |c| c.version = "1.2.3" } }

    before do
      Chef::Config[:treat_deprecation_warnings_as_errors] = false
    end

    it "gives a save URL for the standard cookbook API" do
      expect(cbv.save_url).to eq("cookbooks/tatft/1.2.3")
    end

    it "gives a force save URL for the standard cookbook API" do
      expect(cbv.force_save_url).to eq("cookbooks/tatft/1.2.3?force=true")
    end

    it "is \"ready\"" do
      # WTF is this? what are the valid states? and why aren't they set with encapsulating methods?
      # [Dan 15-Jul-2010]
      expect(cbv.status).to eq(:ready)
    end

    include_examples "to_json equivalent to Chef::JSONCompat.to_json" do
      let(:jsonable) { Chef::CookbookVersion.new("tatft", "/tmp/blah") }
    end

  end
end
