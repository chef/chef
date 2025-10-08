#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Copyright:: Copyright 2010-2020, Ian Meyer
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
require_relative "core/status_presenter"
require_relative "core/formatting_options"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Knife
    class Status < Knife
      include Knife::Core::FormattingOptions

      deps do
        require "chef/search/query" unless defined?(Chef::Search::Query)
      end

      banner "knife status QUERY (options)"

      option :run_list,
        short: "-r",
        long: "--run-list",
        description: "Show the run list"

      option :sort_reverse,
        short: "-s",
        long: "--sort-reverse",
        description: "Sort the status list by last run time descending"

      option :hide_by_mins,
        long: "--hide-by-mins MINS",
        description: "Hide nodes that have run #{ChefUtils::Dist::Infra::CLIENT} in the last MINS minutes"

      def append_to_query(term)
        @query << " AND " unless @query.empty?
        @query << term
      end

      def run
        ui.use_presenter Knife::Core::StatusPresenter

        if config[:long_output]
          opts = {}
        else
          opts = { filter_result:
                 { name: ["name"], ipaddress: ["ipaddress"], ohai_time: ["ohai_time"],
                   cloud: ["cloud"], run_list: ["run_list"], platform: ["platform"],
                   platform_version: ["platform_version"], chef_environment: ["chef_environment"] } }
        end

        @query ||= ""
        append_to_query(@name_args[0]) if @name_args[0]
        append_to_query("chef_environment:#{config[:environment]}") if config[:environment]

        if config[:hide_by_mins]
          hide_by_mins = config[:hide_by_mins].to_i
          time = Time.now.to_i
          # AND NOT is not valid lucene syntax, so don't use append_to_query
          @query << " " unless @query.empty?
          @query << "NOT ohai_time:[#{(time - hide_by_mins * 60)} TO #{time}]"
        end

        @query = @query.empty? ? "*:*" : @query

        all_nodes = []
        q = Chef::Search::Query.new
        Chef::Log.info("Sending query: #{@query}")
        q.search(:node, @query, opts) do |node|
          all_nodes << node
        end

        all_nodes.sort_by! { |n| n["ohai_time"] || 0 }
        all_nodes.reverse! if config[:sort_reverse] || config[:sort_status_reverse]

        output(all_nodes)
      end

    end
  end
end
