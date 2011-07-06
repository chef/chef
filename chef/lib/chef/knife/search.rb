#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'chef/knife/core/node_presenter'

class Chef
  class Knife
    class Search < Knife

      deps do
        require 'chef/node'
        require 'chef/environment'
        require 'chef/api_client'
        require 'chef/search/query'
      end

      include Knife::Core::NodeFormattingOptions

      banner "knife search INDEX QUERY (options)"

      option :sort,
        :short => "-o SORT",
        :long => "--sort SORT",
        :description => "The order to sort the results in",
        :default => nil

      option :start,
        :short => "-b ROW",
        :long => "--start ROW",
        :description => "The row to start returning results at",
        :default => 0,
        :proc => lambda { |i| i.to_i }

      option :rows,
        :short => "-R INT",
        :long => "--rows INT",
        :description => "The number of rows to return",
        :default => 20,
        :proc => lambda { |i| i.to_i }

      option :attribute,
        :short => "-a ATTR",
        :long => "--attribute ATTR",
        :description => "Show only one attribute"

      option :run_list,
        :short => "-r",
        :long => "--run-list",
        :description => "Show only the run list"

      option :id_only,
        :short => "-i",
        :long => "--id-only",
        :description => "Show only the ID of matching objects"

      option :query,
        :short => "-q QUERY",
        :long => "--query QUERY",
        :description => "The search query; useful to protect queries starting with -"

      def run
        if config[:query] && @name_args[1]
          ui.error "please specify query as an argument or an option via -q, not both"
          ui.msg opt_parser
          exit 1
        end
        raw_query = config[:query] || @name_args[1]
        if !raw_query || raw_query.empty?
          ui.error "no query specified"
          ui.msg opt_parser
          exit 1
        end

        if name_args[0].nil?
          ui.error "you must specify an item type to search for"
          exit 1
        end

        if name_args[0] == 'node'
          ui.use_presenter Knife::Core::NodePresenter
        end


        q = Chef::Search::Query.new
        query = URI.escape(raw_query,
                           Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

        result_items = []
        result_count = 0

        rows = config[:rows]
        start = config[:start]
        begin
          q.search(@name_args[0], query, config[:sort], start, rows) do |item|
            formatted_item = format_for_display(item)
            if formatted_item.respond_to?(:has_key?) && !formatted_item.has_key?('id')
              formatted_item['id'] = item.has_key?('id') ? item['id'] : item.name
            end
            result_items << formatted_item
            result_count += 1
          end
        rescue Net::HTTPServerException => e
          msg = Chef::JSONCompat.from_json(e.response.body)["error"].first
          ui.error("knife search failed: #{msg}")
          exit 1
        end

        if ui.interchange?
          output({:results => result_count, :rows => result_items})
        else
          ui.msg "#{result_count} items found"
          ui.msg("\n")
          result_items.each do |item|
            output(item)
            ui.msg("\n")
          end
        end
      end
    end
  end
end




