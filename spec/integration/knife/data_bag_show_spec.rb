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
require "chef/knife/data_bag_show"

describe "knife data bag show", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some data bags" do
    before do
      data_bag "x", {}
      data_bag "canteloupe", {}
      data_bag "rocket", { "falcon9" => { heavy: "true" }, "atlas" => {}, "ariane" => {} }
    end

    it "with an empty data bag" do
      knife("data bag show canteloupe").should_succeed "\n"
    end

    it "with a bag with some items" do
      knife("data bag show rocket").should_succeed <<EOM
ariane
atlas
falcon9
EOM
    end

    it "with a single item" do
      knife("data bag show rocket falcon9").should_succeed <<EOM, stderr: "WARNING: Unencrypted data bag detected, ignoring any provided secret options.\n"
heavy: true
id:    falcon9
EOM
    end
  end
end
