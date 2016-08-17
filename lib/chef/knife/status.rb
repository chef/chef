#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Copyright:: Copyright 2010-2016, Ian Meyer
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
require "chef/knife/core/status_presenter"
require "chef/knife/core/node_presenter"

class Chef
  class Knife
    class Status < Knife
      include Knife::Core::NodeFormattingOptions

      deps do
        require "chef/search/query"
      end

      banner "knife status QUERY (options)"

      option :run_list,
        :short => "-r",
        :long => "--run-list",
        :description => "Show the run list"

      option :sort_reverse,
        :short => "-s",
        :long => "--sort-reverse",
        :description => "Sort the status list by last run time descending"

      option :hide_healthy,
        :short => "-H",
        :long => "--hide-healthy",
        :description => "Hide nodes that have run chef in the last hour. [DEPRECATED] Use --hide-by-mins MINS instead"

      option :hide_by_mins,
        :long => "--hide-by-mins MINS",
        :description => "Hide nodes that have run chef in the last MINS minutes"

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
                   ec2: ["ec2"], run_list: ["run_list"], platform: ["platform"],
                   platform_version: ["platform_version"], chef_environment: ["chef_environment"] } }
        end

        @query ||= ""
        append_to_query(@name_args[0]) if @name_args[0]
        append_to_query("chef_environment:#{config[:environment]}") if config[:environment]

        if config[:hide_healthy]
          ui.warn("-H / --hide-healthy is deprecated. Use --hide-by-mins MINS instead")
          time = Time.now.to_i
          # AND NOT is not valid lucene syntax, so don't use append_to_query
          @query << " " unless @query.empty?
          @query << "NOT ohai_time:[#{(time - 60 * 60)} TO #{time}]"
        end

        if config[:hide_by_mins]
          hidemins = config[:hide_by_mins].to_i
          time = Time.now.to_i
          # AND NOT is not valid lucene syntax, so don't use append_to_query
          @query << " " unless @query.empty?
          @query << "NOT ohai_time:[#{(time - hidemins * 60)} TO #{time}]"
        end

        @query = @query.empty? ? "*:*" : @query

        all_nodes = []
        q = Chef::Search::Query.new
        Chef::Log.info("Sending query: #{@query}")
        q.search(:node, @query, opts) do |node|
          all_nodes << node
        end

        output(all_nodes.sort do |n1, n2|
          if config[:sort_reverse] || Chef::Config[:knife][:sort_status_reverse]
            (n2["ohai_time"] || 0) <=> (n1["ohai_time"] || 0)
          else
            (n1["ohai_time"] || 0) <=> (n2["ohai_time"] || 0)
          end
        end)
      end

    end
  end
end
