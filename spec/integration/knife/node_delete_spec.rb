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

describe "knife node delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some nodes" do
    before do
      node "cons", {}
      node "car", {}
      node "cdr", {}
      node "cat", {}
    end

    it "deletes a node" do
      knife("node delete car", input: "Y").should_succeed <<~EOM
        Do you really want to delete car? (Y/N) Deleted node[car]
EOM

      knife("node list").should_succeed <<~EOM
        cat
        cdr
        cons
EOM
    end

  end
end
