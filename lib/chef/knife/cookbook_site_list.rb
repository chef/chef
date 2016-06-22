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

      def run
        if config[:with_uri]
          cookbooks = Hash.new
          get_cookbook_list.each { |k, v| cookbooks[k] = v["cookbook"] }
          ui.output(format_for_display(cookbooks))
        else
          ui.msg(ui.list(get_cookbook_list.keys.sort, :columns_down))
        end
      end

      def get_cookbook_list(items = 10, start = 0, cookbook_collection = {})
        cookbooks_url = "#{config[:supermarket_site]}/api/v1/cookbooks?items=#{items}&start=#{start}"
        cr = noauth_rest.get(cookbooks_url)
        cr["items"].each do |cookbook|
          cookbook_collection[cookbook["cookbook_name"]] = cookbook
        end
        new_start = start + cr["items"].length
        if new_start < cr["total"]
          get_cookbook_list(items, new_start, cookbook_collection)
        else
          cookbook_collection
        end
      end
    end
  end
end
