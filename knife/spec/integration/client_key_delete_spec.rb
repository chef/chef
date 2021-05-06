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

describe "knife client key delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a client" do
    before do
      client "car", {}
    end

    it "deletes a client" do
      out = "Do you really want to delete the key named new for the client named car? (Y/N) "
      knife("client key create -k new car")
      knife("client key delete car new", input: "Y").should_succeed stdout: out, stderr: <<~EOM
        Deleted key named new for the client named car
      EOM

      knife("client key list car").should_succeed ""
    end

  end
end
