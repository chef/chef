#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

require "chef/knife"

class Chef
  class Knife
    class CookbookSiteList < Knife

      banner "knife cookbook site list (options)"
      category "cookbook site"

      option :with_uri,
        :short => "-w",
        :long => "--with-uri",
        :description => "Show corresponding URIs"

      option :supermarket_site,
        :short => "-m SUPERMARKET_SITE",
        :long => "--supermarket-site SUPERMARKET_SITE",
        :description => "Supermarket Site",
        :default => "https://supermarket.chef.io",
        :proc => Proc.new { |supermarket| Chef::Config[:knife][:supermarket_site] = supermarket }

      option :order,
        :short => "-o ORDER_PREFERENCE",
        :long => "--order ORDER_PREFERENCE",
        :default => "name",
        :description => "Show cookbooks ordered by recently_updated, recently_added, most_downloaded, most_followed, or by name (DEFAULT)."

      option :items,
        :short => "-n NUMBER_OF_ITEMS",
        :long => "--number NUMBER_OF_ITEMS",
        :default => "100",
        :description => "Show number of cookbooks. Default 100."

      def run
        if config[:with_uri]
          ui.output(format_for_display(get_cookbook_list))
        else
          ui.msg(ui.list(get_cookbook_list.keys, :columns_down))
        end
      end

      def get_cookbook_list
        cookbooks_url = "#{config[:supermarket_site]}/api/v1/cookbooks?items=#{config[:items]}&start=0&order=#{config[:order]}"
        cookbook_response = noauth_rest.get(cookbooks_url)
        cookbook_response["items"].each_with_object({}) do |cookbook, collection|
          collection[cookbook["cookbook_name"]] = cookbook["cookbook"]
        end
      end
    end
  end
end
