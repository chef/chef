#
# Author:: John Keiser (<jkeiser@chef.io>)
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

require "knife_spec_helper"
require "support/shared/integration/integration_helper"
require "chef/knife/list"
require "chef/knife/show"

describe "chefignore tests", :workstation do
  include IntegrationSupport
  include KnifeSupport

  when_the_repository "has lots of stuff in it" do
    before do
      file "roles/x.json", {}
      file "environments/x.json", {}
      file "data_bags/bag1/x.json", {}
      file "cookbooks/cookbook1/x.json", {}
    end

    context "and has a chefignore everywhere except cookbooks" do
      before do
        chefignore = "x.json\nroles/x.json\nenvironments/x.json\ndata_bags/bag1/x.json\nbag1/x.json\ncookbooks/cookbook1/x.json\ncookbook1/x.json\n"
        file "chefignore", chefignore
        file "roles/chefignore", chefignore
        file "environments/chefignore", chefignore
        file "data_bags/chefignore", chefignore
        file "data_bags/bag1/chefignore", chefignore
        file "cookbooks/cookbook1/chefignore", chefignore
      end

      it "matching files and directories get ignored" do
        # NOTE: many of the "chefignore" files should probably not show up
        # themselves, but we have other tests that talk about that
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/chefignore
          /data_bags/
          /data_bags/bag1/
          /data_bags/bag1/x.json
          /environments/
          /environments/x.json
          /roles/
          /roles/x.json
        EOM
      end
    end
  end

  when_the_repository "has a cookbook with only chefignored files" do
    before do
      file "cookbooks/cookbook1/templates/default/x.rb", ""
      file "cookbooks/cookbook1/libraries/x.rb", ""
      file "cookbooks/chefignore", "libraries/x.rb\ntemplates/default/x.rb\n"
    end

    it "the cookbook is not listed" do
      knife("list --local -Rfp /").should_succeed(<<~EOM, stderr: "WARN: Cookbook 'cookbook1' is empty or entirely chefignored at #{Chef::Config.chef_repo_path}/cookbooks/cookbook1\n")
        /cookbooks/
      EOM
    end
  end

  when_the_repository "has multiple cookbooks" do
    before do
      file "cookbooks/cookbook1/x.json", {}
      file "cookbooks/cookbook1/y.json", {}
      file "cookbooks/cookbook2/x.json", {}
      file "cookbooks/cookbook2/y.json", {}
    end

    context "and has a chefignore with filenames" do
      before { file "cookbooks/chefignore", "x.json\n" }

      it "matching files and directories get ignored in all cookbooks" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has a chefignore with wildcards" do
      before do
        file "cookbooks/chefignore", "x.*\n"
        file "cookbooks/cookbook1/x.rb", ""
      end

      it "matching files and directories get ignored in all cookbooks" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has a chefignore with relative paths" do
      before do
        file "cookbooks/cookbook1/recipes/x.rb", ""
        file "cookbooks/cookbook2/recipes/y.rb", ""
        file "cookbooks/chefignore", "recipes/x.rb\n"
      end

      it "matching directories get ignored" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/x.json
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/recipes/
          /cookbooks/cookbook2/recipes/y.rb
          /cookbooks/cookbook2/x.json
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has a chefignore with subdirectories" do
      before do
        file "cookbooks/cookbook1/recipes/y.rb", ""
        file "cookbooks/chefignore", "recipes\nrecipes/\n"
      end

      it "matching directories do NOT get ignored" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/recipes/
          /cookbooks/cookbook1/recipes/y.rb
          /cookbooks/cookbook1/x.json
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/x.json
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has a chefignore that ignores all files in a subdirectory" do
      before do
        file "cookbooks/cookbook1/templates/default/x.rb", ""
        file "cookbooks/cookbook1/libraries/x.rb", ""
        file "cookbooks/chefignore", "libraries/x.rb\ntemplates/default/x.rb\n"
      end

      it "ignores the subdirectory entirely" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/x.json
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/x.json
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has an empty chefignore" do
      before do
        file "cookbooks/chefignore", "\n"
      end

      it "nothing is ignored" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/x.json
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/x.json
          /cookbooks/cookbook2/y.json
        EOM
      end
    end

    context "and has a chefignore with comments and empty lines" do
      before do
        file "cookbooks/chefignore", "\n\n # blah\n#\nx.json\n\n"
      end

      it "matching files and directories get ignored in all cookbooks" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/cookbook1/
          /cookbooks/cookbook1/y.json
          /cookbooks/cookbook2/
          /cookbooks/cookbook2/y.json
        EOM
      end
    end
  end

  when_the_repository "has multiple cookbook paths" do
    before :each do
      Chef::Config.cookbook_path = [
        File.join(Chef::Config.chef_repo_path, "cookbooks1"),
        File.join(Chef::Config.chef_repo_path, "cookbooks2"),
      ]
    end

    before do
      file "cookbooks1/mycookbook/metadata.rb", ""
      file "cookbooks1/mycookbook/x.json", {}
      file "cookbooks2/yourcookbook/metadata.rb", ""
      file "cookbooks2/yourcookbook/x.json", ""
    end

    context "and multiple chefignores" do
      before do
        file "cookbooks1/chefignore", "metadata.rb\n"
        file "cookbooks2/chefignore", "x.json\n"
      end
      it "chefignores apply only to the directories they are in" do
        knife("list --local -Rfp /").should_succeed <<~EOM
          /cookbooks/
          /cookbooks/mycookbook/
          /cookbooks/mycookbook/x.json
          /cookbooks/yourcookbook/
          /cookbooks/yourcookbook/metadata.rb
        EOM
      end

      context "and conflicting cookbooks" do
        before do
          file "cookbooks1/yourcookbook/metadata.rb", ""
          file "cookbooks1/yourcookbook/x.json", ""
          file "cookbooks1/yourcookbook/onlyincookbooks1.rb", ""
          file "cookbooks2/yourcookbook/onlyincookbooks2.rb", ""
        end

        it "chefignores apply only to the winning cookbook" do
          knife("list --local -Rfp /").should_succeed(<<~EOM, stderr: "WARN: Child with name 'yourcookbook' found in multiple directories: #{Chef::Config.chef_repo_path}/cookbooks1/yourcookbook and #{Chef::Config.chef_repo_path}/cookbooks2/yourcookbook\n")
            /cookbooks/
            /cookbooks/mycookbook/
            /cookbooks/mycookbook/x.json
            /cookbooks/yourcookbook/
            /cookbooks/yourcookbook/onlyincookbooks1.rb
            /cookbooks/yourcookbook/x.json
          EOM
        end
      end
    end
  end

  when_the_repository "has a cookbook named chefignore" do
    before do
      file "cookbooks/chefignore/metadata.rb", {}
    end
    it "knife list -Rfp /cookbooks shows it" do
      knife("list --local -Rfp /cookbooks").should_succeed <<~EOM
        /cookbooks/chefignore/
        /cookbooks/chefignore/metadata.rb
      EOM
    end
  end

  when_the_repository "has multiple cookbook paths, one with a chefignore file and the other with a cookbook named chefignore" do
    before do
      file "cookbooks1/chefignore", ""
      file "cookbooks1/blah/metadata.rb", ""
      file "cookbooks2/chefignore/metadata.rb", ""
    end
    before :each do
      Chef::Config.cookbook_path = [
        File.join(Chef::Config.chef_repo_path, "cookbooks1"),
        File.join(Chef::Config.chef_repo_path, "cookbooks2"),
      ]
    end
    it "knife list -Rfp /cookbooks shows the chefignore cookbook" do
      knife("list --local -Rfp /cookbooks").should_succeed <<~EOM
        /cookbooks/blah/
        /cookbooks/blah/metadata.rb
        /cookbooks/chefignore/
        /cookbooks/chefignore/metadata.rb
      EOM
    end
  end
end
