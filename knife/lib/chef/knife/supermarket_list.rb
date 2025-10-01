#
# Author:: Christopher Webber (<cwebber@chef.io>)
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
    class SupermarketList < Knife

      banner "knife supermarket list (options)"
      category "supermarket"

      option :with_uri,
        short: "-w",
        long: "--with-uri",
        description: "Show corresponding URIs."

      option :supermarket_site,
        short: "-m SUPERMARKET_SITE",
        long: "--supermarket-site SUPERMARKET_SITE",
        description: "The URL of the Supermarket site.",
        default: "https://supermarket.chef.io"

      option :sort_by,
        long: "--sort-by SORT",
        description: "Use to sort the records",
        in: %w{recently_updated recently_added most_downloaded most_followed}

      option :owned_by,
        short: "-o USER",
        long: "--owned-by USER",
        description: "Show cookbooks that are owned by the USER"

      def run
        if config[:with_uri]
          ui.output(format_for_display(get_cookbook_list))
        else
          ui.msg(ui.list(get_cookbook_list.keys, :columns_down))
        end
      end

      # In order to avoid pagination items limit set to 9999999
      def get_cookbook_list(items = 9999999, start = 0, cookbook_collection = {})
        cookbooks_url = "#{config[:supermarket_site]}/api/v1/cookbooks?items=#{items}&start=#{start}"
        cookbooks_url << "&order=#{config[:sort_by]}" if config[:sort_by]
        cookbooks_url << "&user=#{config[:owned_by]}" if config[:owned_by]
        cr = noauth_rest.get(cookbooks_url)

        cr["items"].each do |cookbook|
          cookbook_collection[cookbook["cookbook_name"]] = cookbook["cookbook"]
        end
        new_start = start + items
        if new_start < cr["total"]
          get_cookbook_list(items, new_start, cookbook_collection)
        else
          cookbook_collection
        end
      end
    end
  end
end
