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

class Chef
  class Knife
    class Status < Knife

      deps do
        require 'highline'
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

      def highline
        @h ||= HighLine.new
      end

      def run
        all_nodes = []
        q = Chef::Search::Query.new
        query = @name_args[0] || "*:*"
        q.search(:node, query) do |node|
          all_nodes << node
        end
        all_nodes.sort { |n1, n2|
          if (config[:sort_reverse] || Chef::Config[:knife][:sort_status_reverse])
            (n2["ohai_time"] or 0) <=> (n1["ohai_time"] or 0)
          else
            (n1["ohai_time"] or 0) <=> (n2["ohai_time"] or 0)
          end
        }.each do |node|
          if node.has_key?("ec2")
            fqdn = node['ec2']['public_hostname']
            ipaddress = node['ec2']['public_ipv4']
          else
            fqdn = node['fqdn']
            ipaddress = node['ipaddress']
          end
          hours, minutes, seconds = time_difference_in_hms(node["ohai_time"])
          hours_text   = "#{hours} hour#{hours == 1 ? ' ' : 's'}"
          minutes_text = "#{minutes} minute#{minutes == 1 ? ' ' : 's'}"
          run_list = ", #{node.run_list}." if config[:run_list]
          if hours > 24
            color = :red
            text = hours_text
          elsif hours >= 1
            color = :yellow
            text = hours_text
          else
            color = :green
            text = minutes_text
          end

          line_parts = Array.new
          line_parts << @ui.color(text, color) + " ago" << node.name
          line_parts << fqdn if fqdn
          line_parts << ipaddress if ipaddress
          line_parts << run_list if run_list

          if node['platform']
            platform = node['platform']
            if node['platform_version']
              platform << " #{node['platform_version']}"
            end
            line_parts << platform
          end
          highline.say(line_parts.join(', ') + '.') unless (config[:hide_healthy] && hours < 1)
        end

      end

      # :nodoc:
      # TODO: this is duplicated from StatusHelper in the Webui. dedup.
      def time_difference_in_hms(unix_time)
        now = Time.now.to_i
        difference = now - unix_time.to_i
        hours = (difference / 3600).to_i
        difference = difference % 3600
        minutes = (difference / 60).to_i
        seconds = (difference % 60)
        return [hours, minutes, seconds]
      end

    end
  end
end
