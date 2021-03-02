#
# Author:: Piyush Awasthi (<piyush.awasthi@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the License);
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative "../knife"

class Chef
  class Knife
    class NodePolicySet < Knife

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node policy set NODE POLICY_GROUP POLICY_NAME (options)"

      def run
        validate_node!
        validate_options!
        node = Chef::Node.load(@name_args[0])
        set_policy(node)
        if node.save
          ui.info "Successfully set the policy on node #{node.name}"
        else
          ui.info "Error in updating node #{node.name}"
        end
      end

      private

      # Set policy name and group to node
      def set_policy(node)
        policy_group, policy_name = @name_args[1..]
        node.policy_name  = policy_name
        node.policy_group = policy_group
      end

      # Validate policy name and policy group
      def validate_options!
        if incomplete_policyfile_options?
          ui.error("Policy group and name must be specified together")
          exit 1
        end
        true
      end

      # Validate node pass in CLI
      def validate_node!
        if @name_args[0].nil?
          ui.error("You must specify a node name")
          show_usage
          exit 1
        end
      end

      # True if one of policy_name or policy_group was given, but not both
      def incomplete_policyfile_options?
        policy_group, policy_name = @name_args[1..]
        (policy_group.nil? || policy_name.nil? || @name_args[1..-1].size > 2)
      end

    end
  end
end
