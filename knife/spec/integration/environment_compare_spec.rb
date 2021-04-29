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

describe "knife environment compare", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some environments" do
    before do
      cookbook "blah", "1.0.1"
      cookbook "blah", "1.1.1"
      cookbook "krad", "1.1.1"
      environment "x", {
        "cookbook_versions" => {
          "blah" => "= 1.0.0",
          "krad" => ">= 1.0.0",
        },
      }
      environment "y", {
        "cookbook_versions" => {
          "blah" => "= 1.1.0",
          "krad" => ">= 1.0.0",
        },
      }
    end

    # rubocop:disable Layout/TrailingWhitespace
    it "displays the cookbooks for a single environment" do
      knife("environment compare x").should_succeed <<~EOM
              x       
        blah  = 1.0.0 
        krad  >= 1.0.0
        
      EOM
    end

    it "compares the cookbooks for two environments" do
      knife("environment compare x y").should_succeed <<~EOM
              x         y       
        blah  = 1.0.0   = 1.1.0 
        krad  >= 1.0.0  >= 1.0.0
        
      EOM
    end

    it "compares the cookbooks for all environments" do
      knife("environment compare --all").should_succeed <<~EOM
              x         y       
        blah  = 1.0.0   = 1.1.0 
        krad  >= 1.0.0  >= 1.0.0
        
      EOM
    end
    # rubocop:enable Layout/TrailingWhitespace
  end
end
