#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

  describe "#recipe_yml_filenames_by_name" do
    let(:cookbook_version) { Chef::CookbookVersion.new("mycb", "/tmp/mycb") }

    def files_for_recipe(extension)
      [
        { name: "recipes/default.#{extension}", full_path: "/home/user/repo/cookbooks/test/recipes/default.#{extension}" },
        { name: "recipes/other.#{extension}", full_path: "/home/user/repo/cookbooks/test/recipes/other.#{extension}" },
      ]
    end
    context "and YAML files present include both a recipes/default.yml and a recipes/default.yaml" do
      before(:each) do
        allow(cookbook_version).to receive(:files_for).with("recipes").and_return(
          [
            { name: "recipes/default.yml", full_path: "/home/user/repo/cookbooks/test/recipes/default.yml" },
            { name: "recipes/default.yaml", full_path: "/home/user/repo/cookbooks/test/recipes/default.yaml" },
          ]
        )
      end
      it "because both are valid and we can't pick, it raises an error that contains the info needed to fix the problem" do
        expect { cookbook_version.recipe_yml_filenames_by_name }
          .to raise_error(Chef::Exceptions::AmbiguousYAMLFile, /.*default.yml.*default.yaml.*update the cookbook to remove/)
      end
    end

    %w{yml yaml}.each do |extension|

      context "and YAML files are present including a recipes/default.#{extension}" do
        before(:each) do
          allow(cookbook_version).to receive(:files_for).with("recipes").and_return(files_for_recipe(extension))
        end

        context "and manifest does not include a root_files/recipe.#{extension}" do
          it "returns all YAML recipes with a correct default of default.#{extension}" do
            expect(cookbook_version.recipe_yml_filenames_by_name).to eq({ "default" => "/home/user/repo/cookbooks/test/recipes/default.#{extension}",
                                                                        "other" => "/home/user/repo/cookbooks/test/recipes/other.#{extension}" })
          end
        end

        context "and manifest also includes a root_files/recipe.#{extension}" do
          let(:root_files) { [{ name: "root_files/recipe.#{extension}", full_path: "/home/user/repo/cookbooks/test/recipe.#{extension}" } ] }
          before(:each) do
            allow(cookbook_version.cookbook_manifest).to receive(:root_files).and_return(root_files)
          end

          it "returns all YAML recipes with a correct default of recipe.#{extension}" do
            expect(cookbook_version.recipe_yml_filenames_by_name).to eq({ "default" => "/home/user/repo/cookbooks/test/recipe.#{extension}",
                                                                         "other" => "/home/user/repo/cookbooks/test/recipes/other.#{extension}" })
          end
        end
      end
    end
  end

  describe "with a cookbook directory named tatft" do
    MD5 = /[0-9a-f]{32}/.freeze

    let(:cookbook_paths_by_type) do
      {
        # Dunno if the paths here are representative of what is set by CookbookLoader...
        all_files: Dir[File.join(cookbook_root, "**", "**")],
      }
    end

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "tatft") }

    describe "and a cookbook with the same name" do

      let(:cookbook_version) do
        Chef::CookbookVersion.new("tatft", cookbook_root).tap do |c|
          # Currently the cookbook loader finds all the files then tells CookbookVersion
          # where they are.
          c.all_files = cookbook_paths_by_type[:all_files]
        end
      end

      # Used to test file-specificity related file lookups
      let(:node) do
        Chef::Node.new.tap do |n|
          n.normal[:platform] = "ubuntu"
          n.normal[:platform_version] = "13.04"
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
        all_files: Dir[File.join(cookbook_root, "**", "**")],
      }
    end

    let(:cookbook_root) { File.join(CHEF_SPEC_DATA, "cb_version_cookbooks", "cookbook2") }

    let(:cookbook_version) do
      Chef::CookbookVersion.new("cookbook2", cookbook_root).tap do |c|
        c.all_files = cookbook_paths_by_type[:all_files]
      end
    end

    # Used to test file-specificity related file lookups
    let(:node) do
      Chef::Node.new.tap do |n|
        n.normal[:platform] = "ubuntu"
        n.normal[:platform_version] = "13.04"
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

end
