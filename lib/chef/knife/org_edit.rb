#
# Author:: Steven Danna (<steve@chef.io>)
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
#

class Chef
  class Knife
    class OrgEdit < Knife
      category "CHEF ORGANIZATION MANAGEMENT"
      banner "knife org edit ORG"

      def run
        org_name = @name_args[0]

        if org_name.nil?
          show_usage
          ui.fatal("You must specify an organization name")
          exit 1
        end

        original_org = root_rest.get("organizations/#{org_name}")
        edited_org = edit_hash(original_org)

        if original_org == edited_org
          ui.msg("Organization unchanged, not saving.")
          exit
        end

        ui.msg edited_org
        root_rest.put("organizations/#{org_name}", edited_org)
        ui.msg("Saved #{org_name}.")
      end
    end
  end
end
