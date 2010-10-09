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
require 'highline'
require 'chef/search/query'

class Chef
  class Knife
    class Status < Knife

      banner "knife status QUERY (options)"

      option :run_list,
        :short => "-r",
        :long => "--run-list",
        :description => "Show the run list"

      def highline
        @h ||= HighLine.new
      end

      def run
        nodes_checked_in = []
        nodes_not_checked_in = []

        q = Chef::Search::Query.new
        query = @name_args[0] || "*:*"
        q.search(:node, query) do |node|
          node.has_key?("ohai_time") ? nodes_checked_in << node : nodes_not_checked_in << node
        end

        nodes_checked_in.sort! { |n1, n2| n1["ohai_time"] <=> n2["ohai_time"] }
        nodes_not_checked_in.sort! { |n1, n2| n1.name <=> n2.name }

        (nodes_not_checked_in + nodes_checked_in).each do |node|
          if node.has_key?("ohai_time")
            if node.has_key?("ec2")
              fqdn = node['ec2']['public_hostname']
              ipaddress = node['ec2']['public_ipv4']
            else
              fqdn = node['fqdn']
              ipaddress = node['ipaddress']
            end

            text, color = time_difference_text_and_color(node["ohai_time"])

            config[:run_list] && !node.run_list.empty? ? run_list = ", #{node.run_list}." : run_list = "."

            highline.say("<%= color('#{text}', #{color}) %> ago, #{node.name}, #{node['platform']} #{node['platform_version']}, #{fqdn}, #{ipaddress}#{run_list}")
          else
            highline.say("<%= color('#{node.name} has never checked in.', RED) %>")
          end
        end
      end

      def time_difference_text_and_color(time)
        hours, minutes, seconds = time_difference_in_hms(time)
        hours_text   = "#{hours} hour#{hours == 1 ? '' : 's'}"
        minutes_text = "#{minutes} minute#{minutes == 1 ? '' : 's'}"

        if hours > 24
          color = "RED"
          text = hours_text
        elsif hours >= 1
          color = "YELLOW"
          text = hours_text
        else
          color = "GREEN"
          text = minutes_text
        end

        return [text, color]
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