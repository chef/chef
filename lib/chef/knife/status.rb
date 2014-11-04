#
# Author:: Ian Meyer (<ianmmeyer@gmail.com>)
# Copyright:: Copyright (c) 2010 Ian Meyer
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
require 'chef/knife/core/status_presenter'

class Chef
  class Knife
    class Status < Knife

      deps do
        require 'chef/search/query'
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
        :description => "Hide nodes that have run chef in the last hour"

      def run
        ui.use_presenter Knife::Core::StatusPresenter
        all_nodes = []
        q = Chef::Search::Query.new
        query = @name_args[0] ? @name_args[0].dup : '*:*' 
        if config[:hide_healthy]
          time = Time.now.to_i
          query_unhealthy = "NOT ohai_time:[" << (time - 60*60).to_s << " TO " << time.to_s << "]"
          query << ' AND ' << query_unhealthy << @name_args[0] if @name_args[0]
          query = query_unhealthy unless @name_args[0]
        end
        q.search(:node, query) do |node|
          all_nodes << node
        end
        output(all_nodes.sort { |n1, n2|
          if (config[:sort_reverse] || Chef::Config[:knife][:sort_status_reverse])
            (n2["ohai_time"] or 0) <=> (n1["ohai_time"] or 0)
          else
            (n1["ohai_time"] or 0) <=> (n2["ohai_time"] or 0)
          end
        })
      end

    end
  end
end
