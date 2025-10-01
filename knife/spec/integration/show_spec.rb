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
require "chef/knife/show"

describe "knife show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

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

    when_the_repository "also has one of each thing" do
      before do
        file "clients/x.json", { "foo" => "bar" }
        file "cookbooks/x/metadata.rb", cb_metadata("x", "1.0.0")
        file "data_bags/x/y.json", { "foo" => "bar" }
        file "environments/_default.json", { "foo" => "bar" }
        file "environments/x.json", { "foo" => "bar" }
        file "nodes/x.json", { "foo" => "bar" }
        file "roles/x.json", { "foo" => "bar" }
        file "users/x.json", { "foo" => "bar" }
      end

      it "knife show /cookbooks/x/metadata.rb shows the remote version" do
        knife("show /cookbooks/x/metadata.rb").should_succeed <<~EOM
          /cookbooks/x/metadata.rb:
          name "x"; version "1.0.0"
        EOM
      end
      it "knife show --local /cookbooks/x/metadata.rb shows the local version" do
        knife("show --local /cookbooks/x/metadata.rb").should_succeed <<~EOM
          /cookbooks/x/metadata.rb:
          name "x"; version "1.0.0"
        EOM
      end
      it "knife show /data_bags/x/y.json shows the remote version" do
        knife("show /data_bags/x/y.json").should_succeed <<~EOM
          /data_bags/x/y.json:
          {
            "id": "y"
          }
        EOM
      end
      it "knife show --local /data_bags/x/y.json shows the local version" do
        knife("show --local /data_bags/x/y.json").should_succeed <<~EOM
          /data_bags/x/y.json:
          {
            "foo": "bar"
          }
        EOM
      end
      it "knife show /environments/x.json shows the remote version" do
        knife("show /environments/x.json").should_succeed <<~EOM
          /environments/x.json:
          {
            "name": "x",
            "description": "",
            "cookbook_versions": {

            },
            "default_attributes": {

            },
            "override_attributes": {

            },
            "json_class": "Chef::Environment",
            "chef_type": "environment"
          }
        EOM
      end
      it "knife show --local /environments/x.json shows the local version" do
        knife("show --local /environments/x.json").should_succeed <<~EOM
          /environments/x.json:
          {
            "foo": "bar"
          }
        EOM
      end
      it "knife show /roles/x.json shows the remote version" do
        knife("show /roles/x.json").should_succeed <<~EOM
          /roles/x.json:
          {
            "name": "x",
            "description": "",
            "json_class": "Chef::Role",
            "chef_type": "role",
            "default_attributes": {

            },
            "override_attributes": {

            },
            "run_list": [

            ],
            "env_run_lists": {

            }
          }
        EOM
      end
      it "knife show --local /roles/x.json shows the local version" do
        knife("show --local /roles/x.json").should_succeed <<~EOM
          /roles/x.json:
          {
            "foo": "bar"
          }
        EOM
      end
      # show directory
      it "knife show /data_bags/x fails" do
        knife("show /data_bags/x").should_fail "ERROR: /data_bags/x: is a directory\n"
      end
      it "knife show --local /data_bags/x fails" do
        knife("show --local /data_bags/x").should_fail "ERROR: /data_bags/x: is a directory\n"
      end
      # show nonexistent file
      it "knife show /environments/nonexistent.json fails" do
        knife("show /environments/nonexistent.json").should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
      end
      it "knife show --local /environments/nonexistent.json fails" do
        knife("show --local /environments/nonexistent.json").should_fail "ERROR: /environments/nonexistent.json: No such file or directory\n"
      end
    end
  end

  when_the_chef_server "has a hash with multiple keys" do
    before do
      environment "x", {
        "default_attributes" => { "foo" => "bar" },
        "cookbook_versions" => { "blah" => "= 1.0.0" },
        "override_attributes" => { "x" => "y" },
        "description" => "woo",
        "name" => "x",
      }
    end
    it "knife show shows the attributes in a predetermined order" do
      knife("show /environments/x.json").should_succeed <<~EOM
        /environments/x.json:
        {
          "name": "x",
          "description": "woo",
          "cookbook_versions": {
            "blah": "= 1.0.0"
          },
          "default_attributes": {
            "foo": "bar"
          },
          "override_attributes": {
            "x": "y"
          },
          "json_class": "Chef::Environment",
          "chef_type": "environment"
        }
      EOM
    end
  end

  when_the_repository "has an environment with bad JSON" do
    before { file "environments/x.json", "{" }
    it "knife show succeeds" do
      knife("show --local /environments/x.json").should_succeed <<~EOM
        /environments/x.json:
        {
      EOM
    end
  end
end
