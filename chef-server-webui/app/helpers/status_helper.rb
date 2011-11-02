#
# Author:: Joe Williams (joe@joetify.com)
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
require 'chef' / 'node'

module Merb
  module StatusHelper
    def time_difference_in_hms(unix_time)
      now = Time.now.to_i
      difference = now - unix_time.to_i
      hours = (difference / 3600).to_i
      difference = difference % 3600
      minutes = (difference / 60).to_i
      seconds = (difference % 60)
      return [hours, minutes, seconds]
    end
    
    def tr_class(node,index)
      index % 2 == 1 ? odd_even = 'odd' : odd_even = 'even'
      node["last_run"].nil? || node["last_run"]["success"] == true ? row_css = odd_even : row_css = "#{odd_even}-fail"
      return row_css
    end
    
    def last_run_summary(node)

      last_run = node['last_run']
      summary = Array.new

      unless last_run.nil?
        if last_run['success'] == false
          summary << 'Last run failed, with exception:'
          summary << last_run['exception']
        else
          if last_run['updated_resources'].nil? || last_run['updated_resources'].empty?
            summary << 'Last run passed, with no changes made.'
          else
            summary << 'Last run passed, updating:'
            last_run['updated_resources'].each {|r| summary << r}
          end
        end
      end

      return summary

    end

  end
end
