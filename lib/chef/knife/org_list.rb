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
    class OrgList < Knife
      category "CHEF ORGANIZATION MANAGEMENT"
      banner "knife org list"

      option :with_uri,
        long: "--with-uri",
        short: "-w",
        description: "Show corresponding URIs"

      option :all_orgs,
        long: "--all-orgs",
        short: "-a",
        description: "Show auto-generated hidden orgs in output"

      def run
        results = root_rest.get("organizations")
        unless config[:all_orgs]
          results = results.select { |k, v| !(k.length == 20 && k =~ /^[a-z]+$/) }
        end
        ui.output(ui.format_list_for_display(results))
      end
    end
  end
end
