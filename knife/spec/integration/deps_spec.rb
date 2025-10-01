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
require "support/shared/context/config"
require "chef/knife/deps"

describe "knife deps", :workstation do
  include IntegrationSupport
  include KnifeSupport

  context "local" do
    when_the_repository "has a role with no run_list" do
      before { file "roles/starring.json", {} }
      it "knife deps reports no dependencies" do
        knife("deps /roles/starring.json").should_succeed "/roles/starring.json\n"
      end
    end

    when_the_repository "has a role with a default run_list" do
      before do
        file "roles/starring.json", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
        file "roles/minor.json", {}
        file "cookbooks/quiche/metadata.rb", 'name "quiche"'
        file "cookbooks/quiche/recipes/default.rb", ""
        file "cookbooks/soup/metadata.rb", 'name "soup"'
        file "cookbooks/soup/recipes/chicken.rb", ""
      end
      it "knife deps reports all dependencies" do
        knife("deps /roles/starring.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
        EOM
      end
    end

    when_the_repository "has a role with an env_run_list" do
      before do
        file "roles/starring.json", { "env_run_lists" => { "desert" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} } }
        file "roles/minor.json", {}
        file "cookbooks/quiche/metadata.rb", 'name "quiche"'
        file "cookbooks/quiche/recipes/default.rb", ""
        file "cookbooks/soup/metadata.rb", 'name "soup"'
        file "cookbooks/soup/recipes/chicken.rb", ""
      end
      it "knife deps reports all dependencies" do
        knife("deps /roles/starring.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
        EOM
      end
    end

    when_the_repository "has a node with no environment or run_list" do
      before { file "nodes/mort.json", {} }
      it "knife deps reports just the node" do
        knife("deps /nodes/mort.json").should_succeed "/nodes/mort.json\n"
      end
    end
    when_the_repository "has a node with an environment" do
      before do
        file "environments/desert.json", {}
        file "nodes/mort.json", { "chef_environment" => "desert" }
      end
      it "knife deps reports just the node" do
        knife("deps /nodes/mort.json").should_succeed "/environments/desert.json\n/nodes/mort.json\n"
      end
    end
    when_the_repository "has a node with roles and recipes in its run_list" do
      before do
        file "roles/minor.json", {}
        file "cookbooks/quiche/metadata.rb", 'name "quiche"'
        file "cookbooks/quiche/recipes/default.rb", ""
        file "cookbooks/soup/metadata.rb", 'name "soup"'
        file "cookbooks/soup/recipes/chicken.rb", ""
        file "nodes/mort.json", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
      end
      it "knife deps reports just the node" do
        knife("deps /nodes/mort.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /nodes/mort.json
        EOM
      end
    end
    when_the_repository "has a cookbook with no dependencies" do
      before do
        file "cookbooks/quiche/metadata.rb", 'name "quiche"'
        file "cookbooks/quiche/recipes/default.rb", ""
      end
      it "knife deps reports just the cookbook" do
        knife("deps /cookbooks/quiche").should_succeed "/cookbooks/quiche\n"
      end
    end
    when_the_repository "has a cookbook with dependencies" do
      before do
        file "cookbooks/kettle/metadata.rb", 'name "kettle"'
        file "cookbooks/quiche/metadata.rb", 'name "quiche"
depends "kettle"'
        file "cookbooks/quiche/recipes/default.rb", ""
      end
      it "knife deps reports just the cookbook" do
        knife("deps /cookbooks/quiche").should_succeed "/cookbooks/kettle\n/cookbooks/quiche\n"
      end
    end
    when_the_repository "has a data bag" do
      before { file "data_bags/bag/item.json", {} }
      it "knife deps reports just the data bag" do
        knife("deps /data_bags/bag/item.json").should_succeed "/data_bags/bag/item.json\n"
      end
    end
    when_the_repository "has an environment" do
      before { file "environments/desert.json", {} }
      it "knife deps reports just the environment" do
        knife("deps /environments/desert.json").should_succeed "/environments/desert.json\n"
      end
    end
    when_the_repository "has a deep dependency tree" do
      before do
        file "roles/starring.json", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
        file "roles/minor.json", {}
        file "cookbooks/quiche/metadata.rb", 'name "quiche"'
        file "cookbooks/quiche/recipes/default.rb", ""
        file "cookbooks/soup/metadata.rb", 'name "soup"'
        file "cookbooks/soup/recipes/chicken.rb", ""
        file "environments/desert.json", {}
        file "nodes/mort.json", { "chef_environment" => "desert", "run_list" => [ "role[starring]" ] }
        file "nodes/bart.json", { "run_list" => [ "role[minor]" ] }
      end

      it "knife deps reports all dependencies" do
        knife("deps /nodes/mort.json").should_succeed <<~EOM
          /environments/desert.json
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps * reports all dependencies of all things" do
        knife("deps /nodes/*").should_succeed <<~EOM
          /roles/minor.json
          /nodes/bart.json
          /environments/desert.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps a b reports all dependencies of a and b" do
        knife("deps /nodes/bart.json /nodes/mort.json").should_succeed <<~EOM
          /roles/minor.json
          /nodes/bart.json
          /environments/desert.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps --tree /* shows dependencies in a tree" do
        knife("deps --tree /nodes/*").should_succeed <<~EOM
          /nodes/bart.json
            /roles/minor.json
          /nodes/mort.json
            /environments/desert.json
            /roles/starring.json
              /roles/minor.json
              /cookbooks/quiche
              /cookbooks/soup
        EOM
      end
      it "knife deps --tree --no-recurse shows only the first level of dependencies" do
        knife("deps --tree --no-recurse /nodes/*").should_succeed <<~EOM
          /nodes/bart.json
            /roles/minor.json
          /nodes/mort.json
            /environments/desert.json
            /roles/starring.json
        EOM
      end
    end

    context "circular dependencies" do
      when_the_repository "has cookbooks with circular dependencies" do
        before do
          file "cookbooks/foo/metadata.rb", 'name "foo"
depends "bar"'
          file "cookbooks/bar/metadata.rb", 'name "bar"
depends "baz"'
          file "cookbooks/baz/metadata.rb", 'name "baz"
depends "foo"'
        end

        it "knife deps prints each once" do
          knife("deps /cookbooks/foo").should_succeed(
            stdout: "/cookbooks/baz\n/cookbooks/bar\n/cookbooks/foo\n"
          )
        end
        it "knife deps --tree prints each once" do
          knife("deps --tree /cookbooks/foo").should_succeed(
            stdout: "/cookbooks/foo\n  /cookbooks/bar\n    /cookbooks/baz\n      /cookbooks/foo\n"
          )
        end
      end
      when_the_repository "has roles with circular dependencies" do
        before do
          file "roles/foo.json", { "run_list" => [ "role[bar]" ] }
          file "roles/bar.json", { "run_list" => [ "role[baz]" ] }
          file "roles/baz.json", { "run_list" => [ "role[foo]" ] }
          file "roles/self.json", { "run_list" => [ "role[self]" ] }
        end
        it "knife deps prints each once" do
          knife("deps /roles/foo.json /roles/self.json").should_succeed <<~EOM
            /roles/baz.json
            /roles/bar.json
            /roles/foo.json
            /roles/self.json
          EOM
        end
        it "knife deps --tree prints each once" do
          knife("deps --tree /roles/foo.json /roles/self.json") do
            expect(stdout).to eq("/roles/foo.json\n  /roles/bar.json\n    /roles/baz.json\n      /roles/foo.json\n/roles/self.json\n  /roles/self.json\n")
            expect(stderr).to eq("WARNING: No knife configuration file found. See https://docs.chef.io/config_rb/ for details.\n")
          end
        end
      end
    end

    context "missing objects" do
      when_the_repository "is empty" do
        it "knife deps /blah reports an error" do
          knife("deps /blah").should_fail(
            exit_code: 2,
            stdout: "/blah\n",
            stderr: "ERROR: /blah: No such file or directory\n"
          )
        end
        it "knife deps /roles/x.json reports an error" do
          knife("deps /roles/x.json").should_fail(
            exit_code: 2,
            stdout: "/roles/x.json\n",
            stderr: "ERROR: /roles/x.json: No such file or directory\n"
          )
        end
        it "knife deps /nodes/x.json reports an error" do
          knife("deps /nodes/x.json").should_fail(
            exit_code: 2,
            stdout: "/nodes/x.json\n",
            stderr: "ERROR: /nodes/x.json: No such file or directory\n"
          )
        end
        it "knife deps /environments/x.json reports an error" do
          knife("deps /environments/x.json").should_fail(
            exit_code: 2,
            stdout: "/environments/x.json\n",
            stderr: "ERROR: /environments/x.json: No such file or directory\n"
          )
        end
        it "knife deps /cookbooks/x reports an error" do
          knife("deps /cookbooks/x").should_fail(
            exit_code: 2,
            stdout: "/cookbooks/x\n",
            stderr: "ERROR: /cookbooks/x: No such file or directory\n"
          )
        end
        it "knife deps /data_bags/bag/item.json reports an error" do
          knife("deps /data_bags/bag/item.json").should_fail(
            exit_code: 2,
            stdout: "/data_bags/bag/item.json\n",
            stderr: "ERROR: /data_bags/bag/item.json: No such file or directory\n"
          )
        end
      end
      when_the_repository "is missing a dependent cookbook" do
        before do
          file "roles/starring.json", { "run_list" => [ "recipe[quiche]"] }
        end
        it "knife deps reports the cookbook, along with an error" do
          knife("deps /roles/starring.json").should_fail(
            exit_code: 2,
            stdout: "/cookbooks/quiche\n/roles/starring.json\n",
            stderr: "ERROR: /cookbooks/quiche: No such file or directory\n"
          )
        end
      end
      when_the_repository "is missing a dependent environment" do
        before do
          file "nodes/mort.json", { "chef_environment" => "desert" }
        end
        it "knife deps reports the environment, along with an error" do
          knife("deps /nodes/mort.json").should_fail(
            exit_code: 2,
            stdout: "/environments/desert.json\n/nodes/mort.json\n",
            stderr: "ERROR: /environments/desert.json: No such file or directory\n"
          )
        end
      end
      when_the_repository "is missing a dependent role" do
        before do
          file "roles/starring.json", { "run_list" => [ "role[minor]"] }
        end
        it "knife deps reports the role, along with an error" do
          knife("deps /roles/starring.json").should_fail(
            exit_code: 2,
            stdout: "/roles/minor.json\n/roles/starring.json\n",
            stderr: "ERROR: /roles/minor.json: No such file or directory\n"
          )
        end
      end
    end
    context "invalid objects" do
      when_the_repository "is empty" do
        it "knife deps / reports itself only" do
          knife("deps /").should_succeed("/\n")
        end
        it "knife deps /roles reports an error" do
          knife("deps /roles").should_fail(
            exit_code: 2,
            stderr: "ERROR: /roles: No such file or directory\n",
            stdout: "/roles\n"
          )
        end
      end
      when_the_repository "has a data bag" do
        before { file "data_bags/bag/item.json", "" }
        it "knife deps /data_bags/bag shows no dependencies" do
          knife("deps /data_bags/bag").should_succeed("/data_bags/bag\n")
        end
      end
      when_the_repository "has a cookbook" do
        before { file "cookbooks/blah/metadata.rb", 'name "blah"' }
        it "knife deps on a cookbook file shows no dependencies" do
          knife("deps /cookbooks/blah/metadata.rb").should_succeed(
            "/cookbooks/blah/metadata.rb\n"
          )
        end
      end
    end
  end

  context "remote" do
    include_context "default config options"

    when_the_chef_server "has a role with no run_list" do
      before { role "starring", {} }
      it "knife deps reports no dependencies" do
        knife("deps --remote /roles/starring.json").should_succeed "/roles/starring.json\n"
      end
    end

    when_the_chef_server "has a role with a default run_list" do
      before do
        role "starring", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
        role "minor", {}
        cookbook "quiche", "1.0.0", { "metadata.rb" => %Q{name "quiche"\nversion "1.0.0"\n}, "recipes" => { "default.rb" => "" } }
        cookbook "soup", "1.0.0", { "metadata.rb" => %Q{name "soup"\nversion "1.0.0"\n}, "recipes" => { "chicken.rb" => "" } }
      end
      it "knife deps reports all dependencies" do
        knife("deps --remote /roles/starring.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
        EOM
      end
    end

    when_the_chef_server "has a role with an env_run_list" do
      before do
        role "starring", { "env_run_lists" => { "desert" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} } }
        role "minor", {}
        cookbook "quiche", "1.0.0", { "metadata.rb" => %Q{name "quiche"\nversion "1.0.0"\n}, "recipes" => { "default.rb" => "" } }
        cookbook "soup", "1.0.0", { "metadata.rb" =>   %Q{name "soup"\nversion "1.0.0"\n}, "recipes" => { "chicken.rb" => "" } }
      end
      it "knife deps reports all dependencies" do
        knife("deps --remote /roles/starring.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
        EOM
      end
    end

    when_the_chef_server "has a node with no environment or run_list" do
      before { node "mort", {} }
      it "knife deps reports just the node" do
        knife("deps --remote /nodes/mort.json").should_succeed "/nodes/mort.json\n"
      end
    end
    when_the_chef_server "has a node with an environment" do
      before do
        environment "desert", {}
        node "mort", { "chef_environment" => "desert" }
      end
      it "knife deps reports just the node" do
        knife("deps --remote /nodes/mort.json").should_succeed "/environments/desert.json\n/nodes/mort.json\n"
      end
    end
    when_the_chef_server "has a node with roles and recipes in its run_list" do
      before do
        role "minor", {}
        cookbook "quiche", "1.0.0", { "metadata.rb" => %Q{name "quiche"\nversion "1.0.0"\n}, "recipes" => { "default.rb" => "" } }
        cookbook "soup", "1.0.0", { "metadata.rb" =>   %Q{name "soup"\nversion "1.0.0"\n}, "recipes" => { "chicken.rb" => "" } }
        node "mort", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
      end
      it "knife deps reports just the node" do
        knife("deps --remote /nodes/mort.json").should_succeed <<~EOM
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /nodes/mort.json
        EOM
      end
    end
    when_the_chef_server "has a cookbook with no dependencies" do
      before do
        cookbook "quiche", "1.0.0", { "metadata.rb" => %Q{name "quiche"\nversion "1.0.0"\n}, "recipes" => { "default.rb" => "" } }
      end
      it "knife deps reports just the cookbook" do
        knife("deps --remote /cookbooks/quiche").should_succeed "/cookbooks/quiche\n"
      end
    end
    when_the_chef_server "has a cookbook with dependencies" do
      before do
        cookbook "kettle", "1.0.0", { "metadata.rb" => %Q{name "kettle"\nversion "1.0.0"\n} }
        cookbook "quiche", "1.0.0", { "metadata.rb" => 'name "quiche"
depends "kettle"', "recipes" => { "default.rb" => "" } }
      end
      it "knife deps reports the cookbook and its dependencies" do
        knife("deps --remote /cookbooks/quiche").should_succeed "/cookbooks/kettle\n/cookbooks/quiche\n"
      end
    end
    when_the_chef_server "has a data bag" do
      before { data_bag "bag", { "item" => {} } }
      it "knife deps reports just the data bag" do
        knife("deps --remote /data_bags/bag/item.json").should_succeed "/data_bags/bag/item.json\n"
      end
    end
    when_the_chef_server "has an environment" do
      before { environment "desert", {} }
      it "knife deps reports just the environment" do
        knife("deps --remote /environments/desert.json").should_succeed "/environments/desert.json\n"
      end
    end
    when_the_chef_server "has a deep dependency tree" do
      before do
        role "starring", { "run_list" => %w{role[minor] recipe[quiche] recipe[soup::chicken]} }
        role "minor", {}
        cookbook "quiche", "1.0.0", { "metadata.rb" => %Q{name "quiche"\nversion "1.0.0"\n}, "recipes" => { "default.rb" => "" } }
        cookbook "soup", "1.0.0", { "metadata.rb" =>   %Q{name "soup"\nversion "1.0.0"\n}, "recipes" => { "chicken.rb" => "" } }
        environment "desert", {}
        node "mort", { "chef_environment" => "desert", "run_list" => [ "role[starring]" ] }
        node "bart", { "run_list" => [ "role[minor]" ] }
      end

      it "knife deps reports all dependencies" do
        knife("deps --remote /nodes/mort.json").should_succeed <<~EOM
          /environments/desert.json
          /roles/minor.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps * reports all dependencies of all things" do
        knife("deps --remote /nodes/*").should_succeed <<~EOM
          /roles/minor.json
          /nodes/bart.json
          /environments/desert.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps a b reports all dependencies of a and b" do
        knife("deps --remote /nodes/bart.json /nodes/mort.json").should_succeed <<~EOM
          /roles/minor.json
          /nodes/bart.json
          /environments/desert.json
          /cookbooks/quiche
          /cookbooks/soup
          /roles/starring.json
          /nodes/mort.json
        EOM
      end
      it "knife deps --tree /* shows dependencies in a tree" do
        knife("deps --remote --tree /nodes/*").should_succeed <<~EOM
          /nodes/bart.json
            /roles/minor.json
          /nodes/mort.json
            /environments/desert.json
            /roles/starring.json
              /roles/minor.json
              /cookbooks/quiche
              /cookbooks/soup
        EOM
      end
      it "knife deps --tree --no-recurse shows only the first level of dependencies" do
        knife("deps --remote --tree --no-recurse /nodes/*").should_succeed <<~EOM
          /nodes/bart.json
            /roles/minor.json
          /nodes/mort.json
            /environments/desert.json
            /roles/starring.json
        EOM
      end
    end

    context "circular dependencies" do
      when_the_chef_server "has cookbooks with circular dependencies" do
        before do
          cookbook "foo", "1.0.0", { "metadata.rb" => 'name "foo"
depends "bar"' }
          cookbook "bar", "1.0.0", { "metadata.rb" => 'name "bar"
depends "baz"' }
          cookbook "baz", "1.0.0", { "metadata.rb" => 'name "baz"
depends "foo"' }
          cookbook "self", "1.0.0", { "metadata.rb" => 'name "self"
depends "self"' }
        end
        it "knife deps prints each once" do
          knife("deps --remote /cookbooks/foo /cookbooks/self").should_succeed <<~EOM
            /cookbooks/baz
            /cookbooks/bar
            /cookbooks/foo
            /cookbooks/self
          EOM
        end
        it "knife deps --tree prints each once" do
          knife("deps --remote --tree /cookbooks/foo /cookbooks/self").should_succeed <<~EOM
            /cookbooks/foo
              /cookbooks/bar
                /cookbooks/baz
                  /cookbooks/foo
            /cookbooks/self
              /cookbooks/self
          EOM
        end
      end
      when_the_chef_server "has roles with circular dependencies" do
        before do
          role "foo", { "run_list" => [ "role[bar]" ] }
          role "bar", { "run_list" => [ "role[baz]" ] }
          role "baz", { "run_list" => [ "role[foo]" ] }
          role "self", { "run_list" => [ "role[self]" ] }
        end
        it "knife deps prints each once" do
          knife("deps --remote /roles/foo.json /roles/self.json").should_succeed <<~EOM
            /roles/baz.json
            /roles/bar.json
            /roles/foo.json
            /roles/self.json
          EOM
        end
        it "knife deps --tree prints each once" do
          knife("deps --remote --tree /roles/foo.json /roles/self.json") do
            expect(stdout).to eq("/roles/foo.json\n  /roles/bar.json\n    /roles/baz.json\n      /roles/foo.json\n/roles/self.json\n  /roles/self.json\n")
            expect(stderr).to eq("WARNING: No knife configuration file found. See https://docs.chef.io/config_rb/ for details.\n")
          end
        end
      end
    end

    context "missing objects" do
      when_the_chef_server "is empty" do
        it "knife deps /blah reports an error" do
          knife("deps --remote /blah").should_fail(
            exit_code: 2,
            stdout: "/blah\n",
            stderr: "ERROR: /blah: No such file or directory\n"
          )
        end
        it "knife deps /roles/x.json reports an error" do
          knife("deps --remote /roles/x.json").should_fail(
            exit_code: 2,
            stdout: "/roles/x.json\n",
            stderr: "ERROR: /roles/x.json: No such file or directory\n"
          )
        end
        it "knife deps /nodes/x.json reports an error" do
          knife("deps --remote /nodes/x.json").should_fail(
            exit_code: 2,
            stdout: "/nodes/x.json\n",
            stderr: "ERROR: /nodes/x.json: No such file or directory\n"
          )
        end
        it "knife deps /environments/x.json reports an error" do
          knife("deps --remote /environments/x.json").should_fail(
            exit_code: 2,
            stdout: "/environments/x.json\n",
            stderr: "ERROR: /environments/x.json: No such file or directory\n"
          )
        end
        it "knife deps /cookbooks/x reports an error" do
          knife("deps --remote /cookbooks/x").should_fail(
            exit_code: 2,
            stdout: "/cookbooks/x\n",
            stderr: "ERROR: /cookbooks/x: No such file or directory\n"
          )
        end
        it "knife deps /data_bags/bag/item reports an error" do
          knife("deps --remote /data_bags/bag/item.json").should_fail(
            exit_code: 2,
            stdout: "/data_bags/bag/item.json\n",
            stderr: "ERROR: /data_bags/bag/item.json: No such file or directory\n"
          )
        end
      end
      when_the_chef_server "is missing a dependent cookbook" do
        before do
          role "starring", { "run_list" => [ "recipe[quiche]"] }
        end
        it "knife deps reports the cookbook, along with an error" do
          knife("deps --remote /roles/starring.json").should_fail(
            exit_code: 2,
            stdout: "/cookbooks/quiche\n/roles/starring.json\n",
            stderr: "ERROR: /cookbooks/quiche: No such file or directory\n"
          )
        end
      end
      when_the_chef_server "is missing a dependent environment" do
        before do
          node "mort", { "chef_environment" => "desert" }
        end
        it "knife deps reports the environment, along with an error" do
          knife("deps --remote /nodes/mort.json").should_fail(
            exit_code: 2,
            stdout: "/environments/desert.json\n/nodes/mort.json\n",
            stderr: "ERROR: /environments/desert.json: No such file or directory\n"
          )
        end
      end
      when_the_chef_server "is missing a dependent role" do
        before do
          role "starring", { "run_list" => [ "role[minor]"] }
        end
        it "knife deps reports the role, along with an error" do
          knife("deps --remote /roles/starring.json").should_fail(
            exit_code: 2,
            stdout: "/roles/minor.json\n/roles/starring.json\n",
            stderr: "ERROR: /roles/minor.json: No such file or directory\n"
          )
        end
      end
    end
    context "invalid objects" do
      when_the_chef_server "is empty" do
        it "knife deps / reports an error" do
          knife("deps --remote /").should_succeed("/\n")
        end
        it "knife deps /roles reports an error" do
          knife("deps --remote /roles").should_succeed("/roles\n")
        end
      end
      when_the_chef_server "has a data bag" do
        before { data_bag "bag", { "item" => {} } }
        it "knife deps /data_bags/bag shows no dependencies" do
          knife("deps --remote /data_bags/bag").should_succeed("/data_bags/bag\n")
        end
      end
      when_the_chef_server "has a cookbook" do
        before do
          cookbook "blah", "1.0.0", { "metadata.rb" => 'name "blah"' }
        end
        it "knife deps on a cookbook file shows no dependencies" do
          knife("deps --remote /cookbooks/blah/metadata.rb").should_succeed(
            "/cookbooks/blah/metadata.rb\n"
          )
        end
      end
    end
  end

  it "knife deps --no-recurse reports an error" do
    knife("deps --no-recurse /").should_fail("ERROR: --no-recurse requires --tree\n")
  end
end
