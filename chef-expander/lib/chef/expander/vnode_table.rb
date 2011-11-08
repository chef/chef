#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
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

require 'yajl'
require 'chef/expander/node'
require 'chef/expander/loggable'

module Chef
  module Expander
    class VNodeTable

      include Loggable

      class InvalidVNodeTableUpdate < ArgumentError; end

      attr_reader :vnodes_by_node

      def initialize(vnode_supervisor)
        @node_update_mutex = Mutex.new
        @vnode_supervisor = vnode_supervisor
        @vnodes_by_node = {}
      end

      def nodes
        @vnodes_by_node.keys
      end

      def update_table(table_update)
        case table_update[:update]
        when "add", "update"
          update_node(table_update)
        when "remove"
          remove_node(table_update)
        else
          raise InvalidVNodeTableUpdate, "no action or action not acceptable: #{table_update.inspect}"
        end
        log.debug { "current vnode table: #{@vnodes_by_node.inspect}" }
      end

      def update_node(node_info)
       @node_update_mutex.synchronize do
          @vnodes_by_node[Node.from_hash(node_info)] = node_info[:vnodes]
        end
      end

      def remove_node(node_info)
        @node_update_mutex.synchronize do
          @vnodes_by_node.delete(Node.from_hash(node_info))
        end
      end

      def leader_node
        if @vnodes_by_node.empty?
          nil
        else
          Array(@vnodes_by_node).reject { |node| node[1].empty? }.sort { |a,b| a[1].min <=> b[1].min }.first[0]
        end
      end

      def local_node_is_leader?
        (Node.local_node == leader_node) || (@vnodes_by_node[Node.local_node].include?(0))
      end

    end
  end
end
