# frozen_string_literal: true
#
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../internal"

module ChefUtils
  module DSL
    module Cloud
      include Internal

      # Determine if the current node is "in the cloud".
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def cloud?(node = __getnode)
        # cloud is always present, but nil if not on a cloud
        !node["cloud"].nil?
      end

      # Return true if the current current node is in EC2.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def ec2?(node = __getnode)
        node.key?("ec2")
      end

      # Return true if the current current node is in GCE.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def gce?(node = __getnode)
        node.key?("gce")
      end

      # Return true if the current current node is in Rackspace.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def rackspace?(node = __getnode)
        node.key?("rackspace")
      end

      # Return true if the current current node is in Eucalyptus.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def eucalyptus?(node = __getnode)
        node.key?("eucalyptus")
      end
      # chef-sugar backcompat method
      alias_method :euca?, :eucalyptus?

      # Return true if the current current node is in Linode.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def linode?(node = __getnode)
        node.key?("linode")
      end

      # Return true if the current current node is in OpenStack.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def openstack?(node = __getnode)
        node.key?("openstack")
      end

      # Return true if the current current node is in Azure.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def azure?(node = __getnode)
        node.key?("azure")
      end

      # Return true if the current current node is in DigitalOcean.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def digital_ocean?(node = __getnode)
        node.key?("digital_ocean")
      end
      # chef-sugar backcompat method
      alias_method :digitalocean?, :digital_ocean?

      # Return true if the current current node is in SoftLayer.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [Boolean]
      #
      def softlayer?(node = __getnode)
        node.key?("softlayer")
      end

      extend self
    end
  end
end
