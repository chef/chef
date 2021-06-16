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

describe "knife role from file", :workstation do
  include IntegrationSupport
  include KnifeSupport

  # include_context "default config options"

  let(:role_dir) { "#{@repository_dir}/roles" }

  when_the_chef_server "is empty" do
    when_the_repository "has some roles" do
      before do

        file "roles/cons.json", <<~EOM
          {
            "name": "cons",
            "description": "An role",
            "json_class": "Chef::role",
            "chef_type": "role",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

        file "roles/car.json", <<~EOM
          {
            "name": "car",
            "description": "A role for list nodes",
            "json_class": "Chef::Role",
            "chef_type": "role",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

        file "roles/cdr.json", <<~EOM
          {
            "name": "cdr",
            "description": "A role for last nodes",
            "json_class": "Chef::Role",
            "chef_type": "role",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

      end

      it "uploads a single file" do
        knife("role from file #{role_dir}/cons.json").should_succeed stderr: <<~EOM
          Updated Role cons
        EOM
      end

      it "uploads many files" do
        knife("role from file #{role_dir}/cons.json #{role_dir}/car.json #{role_dir}/cdr.json").should_succeed stderr: <<~EOM
          Updated Role cons
          Updated Role car
          Updated Role cdr
        EOM
      end

    end
  end
end
