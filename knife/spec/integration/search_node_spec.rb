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

describe "knife node show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a node with a run_list" do
    before do
      node "cons", { run_list: ["recipe[bar]", "recipe[foo]"] }
    end

    it "finds the node" do
      knife("search node name:cons").should_succeed(/Node Name:\s*cons/, stderr: "1 items found\n\n")
    end

    it "does not find a node" do
      knife("search node name:snoc").should_fail("", stderr: "0 items found\n\n", exit_code: 1)
    end
  end
end
