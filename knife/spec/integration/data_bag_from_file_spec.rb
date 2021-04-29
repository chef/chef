#
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

describe "knife data bag from file", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  let(:db_dir) { "#{@repository_dir}/data_bags" }

  when_the_chef_server "has an empty data bag" do
    before do
      data_bag "foo", {}
      data_bag "bar", {}
    end

    when_the_repository "has some data bag items" do
      before do
        file "data_bags/foo/bar.json", { "id" => "bar", "foo" => "bar " }
        file "data_bags/foo/bzr.json", { "id" => "bzr", "foo" => "bar " }
        file "data_bags/foo/cat.json", { "id" => "cat", "foo" => "bar " }
        file "data_bags/foo/dog.json", { "id" => "dog", "foo" => "bar " }
        file "data_bags/foo/encrypted.json", <<~EOM
          {
            "id": "encrypted",
            "password": {
              "encrypted_data": "H6ab5RY9a9JAkS8A0RCMspXtOJh0ai8cNeA4Q3gLO8s=\\n",
              "iv": "uWKKKxrJgtELlGMCOLJdkA==\\n",
              "version": 1,
              "cipher": "aes-256-cbc"
            }
          }
        EOM
        file "data_bags/bar/round_trip.json", <<~EOM
          {
            "name": "data_bag_item_bar_round_trip",
            "json_class": "Chef::DataBagItem",
            "chef_type": "data_bag_item",
            "data_bag": "bar",
            "raw_data": {
              "id": "round_trip",
              "root_password": {
                "encrypted_data": "noDOsTpsTAZlTU5sprhmYZzUDfr8du7hH/zRDOjRAmoTJHTZyfYoR221EOOW\\nXJ1D\\n",
                "iv": "Bnqhfy6n0Hx1wCe9pxHLoA==\\n",
                "version": 1,
                "cipher": "aes-256-cbc"
              },
              "admin_password": {
                "encrypted_data": "TcC7dU1gx6OnE5Ab4i/k42UEf0Nnr7cAyuTHId/LNjNOwpNf7XZc27DQSjuy\\nHPlt\\n",
                "iv": "+TAWJuPWCI2+WB8lGJAyvw==\\n",
                "version": 1,
                "cipher": "aes-256-cbc"
              }
            }
          }
        EOM
      end

      it "uploads a single file" do
        knife("data bag from file foo #{db_dir}/foo/bar.json").should_succeed stderr: <<~EOM
          Updated data_bag_item[foo::bar]
        EOM
      end

      it "uploads a single encrypted file" do
        knife("data bag from file foo #{db_dir}/foo/encrypted.json").should_succeed stderr: <<~EOM
          Updated data_bag_item[foo::encrypted]
        EOM
      end

      it "uploads a file in chef's internal format" do
        pending "chef/chef#4815"
        knife("data bag from file bar #{db_dir}/bar/round_trip.json").should_succeed stderr: <<~EOM
          Updated data_bag_item[bar::round_trip]
        EOM
      end

      it "uploads many files" do
        knife("data bag from file foo #{db_dir}/foo/bar.json #{db_dir}/foo/bzr.json").should_succeed stderr: <<~EOM
          Updated data_bag_item[foo::bar]
          Updated data_bag_item[foo::bzr]
        EOM
      end

      it "uploads a whole directory" do
        knife("data bag from file foo #{db_dir}/foo")
        knife("data bag show foo").should_succeed <<~EOM
          bar
          bzr
          cat
          dog
          encrypted
        EOM
      end

    end
  end
end
