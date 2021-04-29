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

describe "knife node environment set", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a node and an environment" do
    before do
      node "cons", {}
      environment "lisp", {}
    end

    it "sets an environment on a node" do
      knife("node environment set cons lisp").should_succeed(/chef_environment:.*lisp/)
      knife("node show cons -a chef_environment").should_succeed <<~EOM
        cons:
          chef_environment: lisp
      EOM
    end

    it "with no environment" do
      knife("node environment set adam").should_fail stderr: "FATAL: You must specify a node name and an environment.\n",
                                                     stdout: /^USAGE: knife node environment set NODE ENVIRONMENT\n/
    end
  end
end
