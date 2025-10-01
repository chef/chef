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
require "chef/knife/diff"

describe "knife diff", :workstation do
  include IntegrationSupport
  include KnifeSupport

  context "without versioned cookbooks" do
    when_the_chef_server "has one of each thing" do
      before do
        client "x", "{}"
        cookbook "x", "1.0.0"
        data_bag "x", { "y" => "{}" }
        environment "x", "{}"
        node "x", "{}"
        role "x", "{}"
        user "x", "{}"
      end

      when_the_repository "has only top-level directories" do
        before do
          directory "clients"
          directory "cookbooks"
          directory "data_bags"
          directory "environments"
          directory "nodes"
          directory "roles"
          directory "users"
        end

        it "knife diff reports everything as deleted" do
          knife("diff --name-status /").should_succeed <<~EOM
            D\t/clients/chef-validator.json
            D\t/clients/chef-webui.json
            D\t/clients/x.json
            D\t/cookbooks/x
            D\t/data_bags/x
            D\t/environments/_default.json
            D\t/environments/x.json
            D\t/nodes/x.json
            D\t/roles/x.json
            D\t/users/admin.json
            D\t/users/x.json
          EOM
        end
      end

      when_the_repository "has an identical copy of each thing" do

        before do
          file "clients/chef-validator.json", { "validator" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "clients/chef-webui.json", { "admin" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "clients/x.json", { "public_key" => ChefZero::PUBLIC_KEY }
          file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0")
          file "data_bags/x/y.json", {}
          file "environments/_default.json", { "description" => "The default Chef environment" }
          file "environments/x.json", {}
          file "nodes/x.json", { "normal" => { "tags" => [] } }
          file "roles/x.json", {}
          file "users/admin.json", { "admin" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "users/x.json", { "public_key" => ChefZero::PUBLIC_KEY }
        end

        it "knife diff reports no differences" do
          knife("diff /").should_succeed ""
        end

        it "knife diff /environments/nonexistent.json reports an error" do
          knife("diff /environments/nonexistent.json").should_fail "ERROR: /environments/nonexistent.json: No such file or directory on remote or local\n"
        end

        it "knife diff /environments/*.txt reports an error" do
          knife("diff /environments/*.txt").should_fail "ERROR: /environments/*.txt: No such file or directory on remote or local\n"
        end

        context "except the role file" do
          before do
            file "roles/x.json", <<~EOM
              {
                "foo": "bar"
              }
            EOM
          end

          it "knife diff reports the role as different" do
            knife("diff --name-status /").should_succeed <<~EOM
              M\t/roles/x.json
            EOM
          end
        end

        context "as well as one extra copy of each thing" do
          before do
            file "clients/y.json", { "public_key" => ChefZero::PUBLIC_KEY }
            file "cookbooks/x/blah.rb", ""
            file "cookbooks/y/metadata.rb", cb_metadata("y", "1.0.0")
            file "data_bags/x/z.json", {}
            file "data_bags/y/zz.json", {}
            file "environments/y.json", {}
            file "nodes/y.json", {}
            file "roles/y.json", {}
            file "users/y.json", { "public_key" => ChefZero::PUBLIC_KEY }
          end

          it "knife diff reports the new files as added" do
            knife("diff --name-status /").should_succeed <<~EOM
              A\t/clients/y.json
              A\t/cookbooks/x/blah.rb
              A\t/cookbooks/y
              A\t/data_bags/x/z.json
              A\t/data_bags/y
              A\t/environments/y.json
              A\t/nodes/y.json
              A\t/roles/y.json
              A\t/users/y.json
            EOM
          end

          context "when cwd is the data_bags directory" do
            before { cwd "data_bags" }
            it "knife diff reports different data bags" do
              knife("diff --name-status").should_succeed <<~EOM
                A\tx/z.json
                A\ty
              EOM
            end
            it "knife diff * reports different data bags" do
              knife("diff --name-status *").should_succeed <<~EOM
                A\tx/z.json
                A\ty
              EOM
            end
          end
        end
      end

      when_the_repository "is empty" do
        it "knife diff reports everything as deleted" do
          knife("diff --name-status /").should_succeed <<~EOM
            D\t/clients
            D\t/cookbooks
            D\t/data_bags
            D\t/environments
            D\t/nodes
            D\t/roles
            D\t/users
          EOM
        end
      end
    end

    when_the_repository "has a cookbook" do
      before do
        file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0")
        file "cookbooks/x/onlyin1.0.0.rb", ""
      end

      when_the_chef_server "has a later version for the cookbook" do
        before do
          cookbook "x", "1.0.0", { "onlyin1.0.0.rb" => "" }
          cookbook "x", "1.0.1", { "onlyin1.0.1.rb" => "" }
        end

        it "knife diff /cookbooks/x shows differences" do
          knife("diff --name-status /cookbooks/x").should_succeed <<~EOM
            M\t/cookbooks/x/metadata.rb
            D\t/cookbooks/x/onlyin1.0.1.rb
            A\t/cookbooks/x/onlyin1.0.0.rb
          EOM
        end

        it "knife diff --diff-filter=MAT does not show deleted files" do
          knife("diff --diff-filter=MAT --name-status /cookbooks/x").should_succeed <<~EOM
            M\t/cookbooks/x/metadata.rb
            A\t/cookbooks/x/onlyin1.0.0.rb
          EOM
        end
      end

      when_the_chef_server "has an earlier version for the cookbook" do
        before do
          cookbook "x", "1.0.0", { "onlyin1.0.0.rb" => "" }
          cookbook "x", "0.9.9", { "onlyin0.9.9.rb" => "" }
        end
        it "knife diff /cookbooks/x shows no differences" do
          knife("diff --name-status /cookbooks/x").should_succeed ""
        end
      end

      when_the_chef_server "has a later version for the cookbook, and no current version" do
        before do
          cookbook "x", "1.0.1", { "onlyin1.0.1.rb" => "" }
        end

        it "knife diff /cookbooks/x shows the differences" do
          knife("diff --name-status /cookbooks/x").should_succeed <<~EOM
            M\t/cookbooks/x/metadata.rb
            D\t/cookbooks/x/onlyin1.0.1.rb
            A\t/cookbooks/x/onlyin1.0.0.rb
          EOM
        end
      end

      when_the_chef_server "has an earlier version for the cookbook, and no current version" do
        before do
          cookbook "x", "0.9.9", { "onlyin0.9.9.rb" => "" }
        end

        it "knife diff /cookbooks/x shows the differences" do
          knife("diff --name-status /cookbooks/x").should_succeed <<~EOM
            M\t/cookbooks/x/metadata.rb
            D\t/cookbooks/x/onlyin0.9.9.rb
            A\t/cookbooks/x/onlyin1.0.0.rb
          EOM
        end
      end
    end

    context "json diff tests" do
      when_the_repository "has an empty environment file" do
        before do
          file "environments/x.json", {}
        end

        when_the_chef_server "has an empty environment" do
          before { environment "x", {} }
          it "knife diff returns no differences" do
            knife("diff /environments/x.json").should_succeed ""
          end
        end
        when_the_chef_server "has an environment with a different value" do
          before { environment "x", { "description" => "hi" } }
          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
-  "name": "x",
-  "description": "hi"
\+  "name": "x"
 }
/)
          end
        end
      end

      when_the_repository "has an environment file with a value in it" do
        before do
          file "environments/x.json", { "description" => "hi" }
        end

        when_the_chef_server "has an environment with the same value" do
          before do
            environment "x", { "description" => "hi" }
          end
          it "knife diff returns no differences" do
            knife("diff /environments/x.json").should_succeed ""
          end
        end
        when_the_chef_server "has an environment with no value" do
          before do
            environment "x", {}
          end

          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
-  "name": "x"
\+  "name": "x",
\+  "description": "hi"
 }
/)
          end
        end
        when_the_chef_server "has an environment with a different value" do
          before do
            environment "x", { "description" => "lo" }
          end
          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
   "name": "x",
-  "description": "lo"
\+  "description": "hi"
 }
/)
          end
        end
      end
    end

    when_the_chef_server "has an environment" do
      before { environment "x", {} }
      when_the_repository "has an environment with bad JSON" do
        before { file "environments/x.json", "{" }
        it "knife diff reports an error and does a textual diff" do
          error_text = "WARN: Parse error reading #{path_to("environments/x.json")} as JSON: parse error: premature EOF"
          error_match = Regexp.new(Regexp.escape(error_text))
          knife("diff /environments/x.json").should_succeed(/-  "name": "x"/, stderr: error_match)
        end
      end
    end
  end # without versioned cookbooks

  context "with versioned cookbooks" do
    before { Chef::Config[:versioned_cookbooks] = true }

    when_the_chef_server "has one of each thing" do
      before do
        client "x", "{}"
        cookbook "x", "1.0.0"
        data_bag "x", { "y" => "{}" }
        environment "x", "{}"
        node "x", "{}"
        role "x", "{}"
        user "x", "{}"
      end

      when_the_repository "has only top-level directories" do
        before do
          directory "clients"
          directory "cookbooks"
          directory "data_bags"
          directory "environments"
          directory "nodes"
          directory "roles"
          directory "users"
        end

        it "knife diff reports everything as deleted" do
          knife("diff --name-status /").should_succeed <<~EOM
            D\t/clients/chef-validator.json
            D\t/clients/chef-webui.json
            D\t/clients/x.json
            D\t/cookbooks/x-1.0.0
            D\t/data_bags/x
            D\t/environments/_default.json
            D\t/environments/x.json
            D\t/nodes/x.json
            D\t/roles/x.json
            D\t/users/admin.json
            D\t/users/x.json
          EOM
        end
      end

      when_the_repository "has an identical copy of each thing" do
        before do
          file "clients/chef-validator.json", { "validator" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "clients/chef-webui.json", { "admin" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "clients/x.json", { "public_key" => ChefZero::PUBLIC_KEY }
          file "cookbooks/x-1.0.0/metadata.rb", cb_metadata("x", "1.0.0")
          file "data_bags/x/y.json", {}
          file "environments/_default.json", { "description" => "The default Chef environment" }
          file "environments/x.json", {}
          file "nodes/x.json", { "normal" => { "tags" => [] } }
          file "roles/x.json", {}
          file "users/admin.json", { "admin" => true, "public_key" => ChefZero::PUBLIC_KEY }
          file "users/x.json", { "public_key" => ChefZero::PUBLIC_KEY }
        end

        it "knife diff reports no differences" do
          knife("diff /").should_succeed ""
        end

        it "knife diff /environments/nonexistent.json reports an error" do
          knife("diff /environments/nonexistent.json").should_fail "ERROR: /environments/nonexistent.json: No such file or directory on remote or local\n"
        end

        it "knife diff /environments/*.txt reports an error" do
          knife("diff /environments/*.txt").should_fail "ERROR: /environments/*.txt: No such file or directory on remote or local\n"
        end

        context "except the role file" do
          before do
            file "roles/x.json", <<~EOM
              {
                "foo": "bar"
              }
            EOM
          end

          it "knife diff reports the role as different" do
            knife("diff --name-status /").should_succeed <<~EOM
              M\t/roles/x.json
            EOM
          end
        end

        context "as well as one extra copy of each thing" do
          before do
            file "clients/y.json", {}
            file "cookbooks/x-1.0.0/blah.rb", ""
            file "cookbooks/x-2.0.0/metadata.rb", cb_metadata("x", "2.0.0")
            file "cookbooks/y-1.0.0/metadata.rb", cb_metadata("y", "1.0.0")
            file "data_bags/x/z.json", {}
            file "data_bags/y/zz.json", {}
            file "environments/y.json", {}
            file "nodes/y.json", {}
            file "roles/y.json", {}
            file "users/y.json", {}
          end

          it "knife diff reports the new files as added" do
            knife("diff --name-status /").should_succeed <<~EOM
              A\t/clients/y.json
              A\t/cookbooks/x-1.0.0/blah.rb
              A\t/cookbooks/x-2.0.0
              A\t/cookbooks/y-1.0.0
              A\t/data_bags/x/z.json
              A\t/data_bags/y
              A\t/environments/y.json
              A\t/nodes/y.json
              A\t/roles/y.json
              A\t/users/y.json
            EOM
          end

          context "when cwd is the data_bags directory" do
            before { cwd "data_bags" }
            it "knife diff reports different data bags" do
              knife("diff --name-status").should_succeed <<~EOM
                A\tx/z.json
                A\ty
              EOM
            end
            it "knife diff * reports different data bags" do
              knife("diff --name-status *").should_succeed <<~EOM
                A\tx/z.json
                A\ty
              EOM
            end
          end
        end
      end

      when_the_repository "is empty" do
        it "knife diff reports everything as deleted" do
          knife("diff --name-status /").should_succeed <<~EOM
            D\t/clients
            D\t/cookbooks
            D\t/data_bags
            D\t/environments
            D\t/nodes
            D\t/roles
            D\t/users
          EOM
        end
      end
    end

    when_the_repository "has a cookbook" do
      before do
        file "cookbooks/x-1.0.0/metadata.rb", cb_metadata("x", "1.0.0")
        file "cookbooks/x-1.0.0/onlyin1.0.0.rb", ""
      end

      when_the_chef_server "has a later version for the cookbook" do
        before do
          cookbook "x", "1.0.0", { "onlyin1.0.0.rb" => "" }
          cookbook "x", "1.0.1", { "onlyin1.0.1.rb" => "" }
        end

        it "knife diff /cookbooks shows differences" do
          knife("diff --name-status /cookbooks").should_succeed <<~EOM
            D\t/cookbooks/x-1.0.1
          EOM
        end

        it "knife diff --diff-filter=MAT does not show deleted files" do
          knife("diff --diff-filter=MAT --name-status /cookbooks").should_succeed ""
        end
      end

      when_the_chef_server "has an earlier version for the cookbook" do
        before do
          cookbook "x", "1.0.0", { "onlyin1.0.0.rb" => "" }
          cookbook "x", "0.9.9", { "onlyin0.9.9.rb" => "" }
        end
        it "knife diff /cookbooks shows the differences" do
          knife("diff --name-status /cookbooks").should_succeed "D\t/cookbooks/x-0.9.9\n"
        end
      end

      when_the_chef_server "has a later version for the cookbook, and no current version" do
        before do
          cookbook "x", "1.0.1", { "onlyin1.0.1.rb" => "" }
        end

        it "knife diff /cookbooks shows the differences" do
          knife("diff --name-status /cookbooks").should_succeed <<~EOM
            D\t/cookbooks/x-1.0.1
            A\t/cookbooks/x-1.0.0
          EOM
        end
      end

      when_the_chef_server "has an earlier version for the cookbook, and no current version" do
        before do
          cookbook "x", "0.9.9", { "onlyin0.9.9.rb" => "" }
        end

        it "knife diff /cookbooks shows the differences" do
          knife("diff --name-status /cookbooks").should_succeed <<~EOM
            D\t/cookbooks/x-0.9.9
            A\t/cookbooks/x-1.0.0
          EOM
        end
      end
    end

    context "json diff tests" do
      when_the_repository "has an empty environment file" do
        before { file "environments/x.json", {} }
        when_the_chef_server "has an empty environment" do
          before { environment "x", {} }
          it "knife diff returns no differences" do
            knife("diff /environments/x.json").should_succeed ""
          end
        end
        when_the_chef_server "has an environment with a different value" do
          before { environment "x", { "description" => "hi" } }
          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
-  "name": "x",
-  "description": "hi"
\+  "name": "x"
 }
/)
          end
        end
      end

      when_the_repository "has an environment file with a value in it" do
        before do
          file "environments/x.json", { "description" => "hi" }
        end

        when_the_chef_server "has an environment with the same value" do
          before do
            environment "x", { "description" => "hi" }
          end
          it "knife diff returns no differences" do
            knife("diff /environments/x.json").should_succeed ""
          end
        end
        when_the_chef_server "has an environment with no value" do
          before { environment "x", {} }
          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
-  "name": "x"
\+  "name": "x",
\+  "description": "hi"
 }
/)
          end
        end
        when_the_chef_server "has an environment with a different value" do
          before do
            environment "x", { "description" => "lo" }
          end
          it "knife diff reports the difference" do
            knife("diff /environments/x.json").should_succeed(/
 {
   "name": "x",
-  "description": "lo"
\+  "description": "hi"
 }
/)
          end
        end
      end
    end

    when_the_chef_server "has an environment" do
      before { environment "x", {} }
      when_the_repository "has an environment with bad JSON" do
        before { file "environments/x.json", "{" }
        it "knife diff reports an error and does a textual diff" do
          error_text = "WARN: Parse error reading #{path_to("environments/x.json")} as JSON: parse error: premature EOF"
          error_match = Regexp.new(Regexp.escape(error_text))
          knife("diff /environments/x.json").should_succeed(/-  "name": "x"/, stderr: error_match)
        end
      end
    end
  end # without versioned cookbooks
end
