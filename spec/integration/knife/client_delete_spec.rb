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

describe "knife client delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some clients" do
    before do
      client "cons", {}
      client "car", {}
      client "car-validator", { validator: true }
      client "cdr", {}
      client "cat", {}
    end

    it "deletes a client" do
      knife("client delete car", input: "Y").should_succeed <<~EOM
        Do you really want to delete car? (Y/N) Deleted client[car]
EOM

      knife("client list").should_succeed <<~EOM
        car-validator
        cat
        cdr
        chef-validator
        chef-webui
        cons
EOM
    end

    it "refuses to delete a validator normally" do
      knife("client delete car-validator", input: "Y").should_fail exit_code: 2, stdout: "Do you really want to delete car-validator? (Y/N) ", stderr: <<~EOM
        FATAL: You must specify --delete-validators to delete the validator client car-validator
EOM
    end

    it "deletes a validator correctly" do
      knife("client delete car-validator -D", input: "Y").should_succeed <<~EOM
        Do you really want to delete car-validator? (Y/N) Deleted client[car-validator]
EOM
    end

  end
end
