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
require "chef/knife/data_bag_delete"

describe "knife data bag delete", :workstation do
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
      knife("data bag delete canteloupe", input: "y").should_succeed <<~EOM
        Do you really want to delete canteloupe? (Y/N) Deleted data_bag[canteloupe]
      EOM
    end

    it "with a bag with some items" do
      knife("data bag delete rocket", input: "y").should_succeed <<~EOM
        Do you really want to delete rocket? (Y/N) Deleted data_bag[rocket]
      EOM
    end

    it "with a single item" do
      knife("data bag delete rocket falcon9", input: "y").should_succeed <<~EOM
        Do you really want to delete falcon9? (Y/N) Deleted data_bag_item[falcon9]
      EOM
    end

    it "choosing not to delete" do
      knife("data bag delete rocket falcon9", input: "n").should_succeed <<~EOM, exit_code: 3
        Do you really want to delete falcon9? (Y/N) You said no, so I'm done here.
      EOM
    end
  end
end
