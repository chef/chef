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
require "chef/knife/cookbook_list"

describe "knife cookbook list", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a cookbook" do
    before do
      cookbook "x", "1.0.0"
      cookbook "x", "0.6.5"
      cookbook "x", "0.6.0"
      cookbook "y", "0.6.5"
      cookbook "y", "0.6.0"
      cookbook "z", "0.6.5"
    end

    it "knife cookbook list shows all the cookbooks" do
      knife("cookbook list").should_succeed <<~EOM
        x   1.0.0
        y   0.6.5
        z   0.6.5
      EOM
    end

    it "knife cookbook list -a shows all the versions of all the cookbooks" do
      knife("cookbook list -a").should_succeed <<~EOM
        x   1.0.0  0.6.5  0.6.0
        y   0.6.5  0.6.0
        z   0.6.5
      EOM
    end

  end
end
