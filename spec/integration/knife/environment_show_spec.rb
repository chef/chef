#
# Copyright:: Copyright 2013-2016, Chef Software Inc.
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

require "support/shared/integration/integration_helper"
require "support/shared/context/config"

describe "knife environment show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some environments" do
    before do
      environment "b", {
        "default_attributes" => { "foo" => "bar" },
      }
    end

    # rubocop:disable Style/TrailingWhitespace
    it "shows an environment" do
      knife("environment show b").should_succeed <<EOM
chef_type:           environment
cookbook_versions:
default_attributes:
  foo: bar
description:         
json_class:          Chef::Environment
name:                b
override_attributes:
EOM
    end
    # rubocop:enable Style/TrailingWhitespace

    it "shows the requested attribute of an environment" do
      pending "KnifeSupport doesn't appear to pass this through correctly"
      knife("environment show b -a foo").should_succeed <<EOM
b:
  foo: bar
EOM
    end
  end
end
