#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Nuo Yan (<nuo@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class CookbookList < Knife

      banner "knife cookbook list (options)"

      option :with_uri,
        short: "-w",
        long: "--with-uri",
        description: "Show corresponding URIs."

      option :all_versions,
        short: "-a",
        long: "--all",
        description: "Show all available versions."

      def run
        env          = config[:environment]
        num_versions = config[:all_versions] ? "num_versions=all" : "num_versions=1"
        api_endpoint = env ? "/environments/#{env}/cookbooks?#{num_versions}" : "/cookbooks?#{num_versions}"
        cookbook_versions = rest.get(api_endpoint)
        ui.output(format_cookbook_list_for_display(cookbook_versions))
      end
    end
  end
end
