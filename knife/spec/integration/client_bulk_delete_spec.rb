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

describe "knife client bulk delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some clients" do
    before do
      client "concat", {}
      client "cons", {}
      client "car", {}
      client "cdr", {}
      client "cat", {}
    end

    it "deletes all matching clients" do
      knife("client bulk delete ^ca.*", input: "Y").should_succeed <<~EOM
        The following clients will be deleted:

        car  cat

        Are you sure you want to delete these clients? (Y/N) Deleted client car
        Deleted client cat
      EOM

      knife("client list").should_succeed <<~EOM
        cdr
        chef-validator
        chef-webui
        concat
        cons
      EOM
    end

    it "deletes all matching clients when unanchored" do
      knife("client bulk delete ca.*", input: "Y").should_succeed <<~EOM
        The following clients will be deleted:

        car     cat     concat

        Are you sure you want to delete these clients? (Y/N) Deleted client car
        Deleted client cat
        Deleted client concat
      EOM

      knife("client list").should_succeed <<~EOM
        cdr
        chef-validator
        chef-webui
        cons
      EOM
    end
  end

  when_the_chef_server "has a validator client" do
    before do
      client "cons", {}
      client "car", {}
      client "car-validator", { validator: true }
      client "cdr", {}
      client "cat", {}
    end

    it "refuses to delete a validator normally" do
      knife("client bulk delete ^ca.*", input: "Y").should_succeed <<~EOM
        The following clients are validators and will not be deleted:

        car-validator

        You must specify --delete-validators to delete the validator clients
        The following clients will be deleted:

        car  cat

        Are you sure you want to delete these clients? (Y/N) Deleted client car
        Deleted client cat
      EOM

      knife("client list").should_succeed <<~EOM
        car-validator
        cdr
        chef-validator
        chef-webui
        cons
      EOM
    end

    it "deletes a validator when told to" do
      knife("client bulk delete ^ca.* -D", input: "Y\nY").should_succeed <<~EOM
        The following validators will be deleted:

        car-validator

        Are you sure you want to delete these validators? (Y/N) Deleted client car-validator
        The following clients will be deleted:

        car  cat

        Are you sure you want to delete these clients? (Y/N) Deleted client car
        Deleted client cat
      EOM

      knife("client list").should_succeed <<~EOM
        cdr
        chef-validator
        chef-webui
        cons
      EOM
    end
  end
end
