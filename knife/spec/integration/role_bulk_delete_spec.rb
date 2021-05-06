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

describe "knife role bulk delete", :workstation do
  include IntegrationSupport
  include KnifeSupport

  include_context "default config options"

  when_the_chef_server "has some roles" do
    before do
      role "cons", {}
      role "car", {}
      role "cdr", {}
      role "cat", {}
    end

    it "deletes all matching roles" do
      knife("role bulk delete ^ca.*", input: "Y").should_succeed <<~EOM
        The following roles will be deleted:

        car  cat

        Are you sure you want to delete these roles? (Y/N) Deleted role car
        Deleted role cat
      EOM

      knife("role list").should_succeed <<~EOM
        cdr
        cons
      EOM
    end

  end
end
