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
require "chef/knife/cookbook_bulk_delete"

describe "knife cookbook bulk delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has a cookbook" do
    before do
      cookbook "foo", "1.0.0"
      cookbook "foo", "0.6.5"
      cookbook "fox", "0.6.0"
      cookbook "fox", "0.6.5"
      cookbook "fax", "0.6.0"
      cookbook "zfa", "0.6.5"
    end

    # rubocop:disable Layout/TrailingWhitespace
    it "knife cookbook bulk delete deletes all matching cookbooks" do
      stdout = <<~EOM
        All versions of the following cookbooks will be deleted:
        
        foo  fox
        
        Do you really want to delete these cookbooks? (Y/N) 
      EOM

      stderr = <<~EOM
        Deleted cookbook  foo                       [1.0.0]
        Deleted cookbook  foo                       [0.6.5]
        Deleted cookbook  fox                       [0.6.5]
        Deleted cookbook  fox                       [0.6.0]
      EOM

      knife("cookbook bulk delete ^fo.*", input: "Y").should_succeed(stderr: stderr, stdout: stdout)

      knife("cookbook list -a").should_succeed <<~EOM
        fax   0.6.0
        zfa   0.6.5
      EOM
    end
    # rubocop:enable Layout/TrailingWhitespace

  end
end
