#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2015 Chef Software, Inc.
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

require 'chef/log'
require 'chef/rest'
require 'chef/run_context'
require 'chef/config'
require 'chef/node'
require 'chef/exceptions'

class Chef
  module PolicyBuilder

    # PolicyBuilder that selects either a Policyfile or non-Policyfile
    # implementation based on the content of the node object.
    class Dynamic

      attr_reader :node
      attr_reader :node_name
      attr_reader :ohai_data
      attr_reader :json_attribs
      attr_reader :override_runlist
      attr_reader :events

      def initialize(node_name, ohai_data, json_attribs, override_runlist, events)
        @implementation = nil

        @node_name = node_name
        @ohai_data = ohai_data
        @json_attribs = json_attribs
        @override_runlist = override_runlist
        @events = events

        @node = nil
      end

      ## PolicyBuilder API ##

      # Loads the node state from the server, then picks the correct
      # implementation class based on the node and json_attribs.
      def load_node
        events.node_load_start(node_name, config)
        Chef::Log.debug("Building node object for #{node_name}")

        @node =
          if Chef::Config[:solo]
            Chef::Node.build(node_name)
          else
            Chef::Node.find_or_create(node_name)
          end
        select_implementation(node)
        implementation.finish_load_node(node)
        node
      rescue Exception => e
        events.node_load_failed(node_name, e, config)
        raise
      end

      ## Delegated Methods ##

      def original_runlist
        implementation.original_runlist
      end

      def run_context
        implementation.run_context
      end

      def run_list_expansion
        implementation.run_list_expansion
      end

      def build_node
        implementation.build_node
      end

      def setup_run_context(specific_recipes=nil)
        implementation.setup_run_context(specific_recipes)
      end

      def expand_run_list
        implementation.expand_run_list
      end

      def sync_cookbooks
        implementation.sync_cookbooks
      end

      def temporary_policy?
        implementation.temporary_policy?
      end

      ## Internal Public API ##

      def implementation
        @implementation or raise Exceptions::InvalidPolicybuilderCall, "#load_node must be called before other policy builder methods"
      end

      def select_implementation(node)
        if policyfile_set_in_config? || policyfile_attribs_in_node_json? || node_has_policyfile_attrs?(node)
          @implementation = Policyfile.new(node_name, ohai_data, json_attribs, override_runlist, events)
        else
          @implementation = ExpandNodeObject.new(node_name, ohai_data, json_attribs, override_runlist, events)
        end
      end

      def config
        Chef::Config
      end

      private

      def node_has_policyfile_attrs?(node)
        node.policy_name || node.policy_group
      end

      def policyfile_attribs_in_node_json?
        json_attribs.key?("policy_name") || json_attribs.key?("policy_group")
      end

      def policyfile_set_in_config?
        config[:use_policyfile] || config[:policy_name] || config[:policy_group]
      end

    end
  end
end
