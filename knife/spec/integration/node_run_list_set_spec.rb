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

describe "knife node run list set", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a node with a run_list" do
    before do
      node "cons", { run_list: ["recipe[bar]", "recipe[foo]"] }
    end

    it "sets the run list" do
      knife("node run list set cons recipe[bar]").should_succeed(/run_list:\s*recipe\[bar\]\n/m)
    end

    it "with no role or recipe" do
      knife("node run list set cons").should_fail stderr: "FATAL: You must supply both a node name and a run list.\n",
                                                  stdout: /^USAGE: knife node run_list set NODE ENTRIES \(options\)/m
    end
  end
end
