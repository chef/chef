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

describe "knife environment show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some environments" do
    before do
      environment "b", {
        "default_attributes" => { "foo" => "bar", "baz" => { "raz.my" => "mataz" } },
      }
    end

    # rubocop:disable Layout/TrailingWhitespace
    it "shows an environment" do
      knife("environment show b").should_succeed <<~EOM
        chef_type:           environment
        cookbook_versions:
        default_attributes:
          baz:
            raz.my: mataz
          foo: bar
        description:         
        json_class:          Chef::Environment
        name:                b
        override_attributes:
      EOM
    end
    # rubocop:enable Layout/TrailingWhitespace

    it "shows the requested attribute of an environment" do
      knife("environment show b -a default_attributes").should_succeed <<~EOM
        b:
          default_attributes:
            baz:
              raz.my: mataz
            foo: bar
      EOM
    end

    it "shows the requested nested attribute of an environment" do
      knife("environment show b -a default_attributes.baz").should_succeed <<~EON
        b:
          default_attributes.baz:
            raz.my: mataz
      EON
    end

    it "shows the requested attribute of an environment with custom field separator" do
      knife("environment show b -S: -a default_attributes:baz").should_succeed <<~EOT
        b:
          default_attributes:baz:
            raz.my: mataz
      EOT
    end
  end
end
