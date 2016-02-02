#
# Author:: John Keiser (<jkeiser@chef.io>)
# Copyright:: Copyright 2015-2016, Chef Software Inc.
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

require "chef/node_map"

class Chef
  class Platform
    class PriorityMap < Chef::NodeMap
      def priority(resource_name, priority_array, *filter)
        set_priority_array(resource_name.to_sym, priority_array, *filter)
      end

      # @api private
      def get_priority_array(node, key)
        get(node, key)
      end

      # @api private
      def set_priority_array(key, priority_array, *filter, &block)
        priority_array = Array(priority_array)
        set(key, priority_array, *filter, &block)
        priority_array
      end
    end
  end
end
