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

      banner "Sub-Command: status"

      def highline
        @h ||= HighLine.new
      end

      def run
        Chef::Search::Query.new.search(:node, '*:*') do |node|
          current_time = DateTime.now
          date = DateTime.parse(Time.at(node["ohai_time"]).to_s)
          hours, minutes, seconds, frac = DateTime.day_fraction_to_time(current_time - date)
          hours_text   = "#{hours} hour#{hours == 1 ? ' ' : 's'}"
          minutes_text = "#{minutes} minute#{minutes == 1 ? ' ' : 's'}"
          if hours > 24
            highline.say("<%= color('#{hours_text}', RED) %> ago, #{node['fqdn']} checked in as a #{node['platform']} #{node['platform_version']} node.")
          elsif hours > 1
            highline.say("<%= color('#{hours_text}', YELLOW) %> ago, #{node['fqdn']} checked in as a #{node['platform']} #{node['platform_version']} node.")
          elsif hours == 0
            highline.say("<%= color('#{minutes_text}', GREEN) %> ago, #{node['fqdn']} checked in as a #{node['platform']} #{node['platform_version']} node.")
          end
        end
      end
    end
  end
end