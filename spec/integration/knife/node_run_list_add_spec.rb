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

describe "knife node run list add", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a node with no run_list" do
    before do
      node "cons", {}
    end

    it "sets the run list" do
      knife("node run list add cons recipe[foo]").should_succeed /run_list:\s*recipe\[foo\]\n/
    end
  end

  when_the_chef_server "has a node with a run_list" do
    before do
      node "cons", { run_list: ["recipe[bar]"] }
    end

    it "appends to the run list" do
      knife("node run list add cons recipe[foo]").should_succeed /run_list:\n\s*recipe\[bar\]\n\s*recipe\[foo\]\n/m
    end

    it "adds to the run list before the specified item" do
      knife("node run list add cons -b recipe[bar] recipe[foo]").should_succeed /run_list:\n\s*recipe\[foo\]\n\s*recipe\[bar\]\n/m
    end

    it "adds to the run list after the specified item" do
      knife("node run list add cons -a recipe[bar] recipe[foo]").should_succeed /run_list:\n\s*recipe\[bar\]\n\s*recipe\[foo\]\n/m
    end
  end
end
