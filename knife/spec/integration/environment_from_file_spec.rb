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

describe "knife environment from file", :workstation do
  include IntegrationSupport
  include KnifeSupport

  # include_context "default config options"

  let(:env_dir) { "#{@repository_dir}/environments" }

  when_the_chef_server "is empty" do
    when_the_repository "has some environments" do
      before do

        file "environments/cons.json", <<~EOM
          {
            "name": "cons",
            "description": "An environment",
            "cookbook_versions": {

            },
            "json_class": "Chef::Environment",
            "chef_type": "environment",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

        file "environments/car.json", <<~EOM
          {
            "name": "car",
            "description": "An environment for list nodes",
            "cookbook_versions": {

            },
            "json_class": "Chef::Environment",
            "chef_type": "environment",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

        file "environments/cdr.json", <<~EOM
          {
            "name": "cdr",
            "description": "An environment for last nodes",
            "cookbook_versions": {

            },
            "json_class": "Chef::Environment",
            "chef_type": "environment",
            "default_attributes": {
              "hola": "Amigos!"
            },
            "override_attributes": {

            }
          }
        EOM

      end

      it "uploads a single file" do
        knife("environment from file #{env_dir}/cons.json").should_succeed stderr: <<~EOM
          Updated Environment cons
        EOM
      end

      it "uploads many files" do
        knife("environment from file #{env_dir}/cons.json #{env_dir}/car.json #{env_dir}/cdr.json").should_succeed stderr: <<~EOM
          Updated Environment cons
          Updated Environment car
          Updated Environment cdr
        EOM
      end

      it "uploads all environments in the repository" do
        cwd(".")
        knife("environment from file --all")
        knife("environment list").should_succeed <<~EOM
          _default
          car
          cdr
          cons
        EOM
      end

    end
  end
end
