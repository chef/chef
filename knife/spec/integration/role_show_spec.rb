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

describe "knife role show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some roles" do
    before do
      role "cons", {}
      role "car", {}
      role "cdr", {}
      role "cat", {}
    end

    # rubocop:disable Layout/TrailingWhitespace
    it "shows a cookbook" do
      knife("role show cons").should_succeed <<~EOM
        chef_type:           role
        default_attributes:
        description:         
        env_run_lists:
        json_class:          Chef::Role
        name:                cons
        override_attributes:
        run_list:
      EOM
    end
    # rubocop:enable Layout/TrailingWhitespace

  end
end
