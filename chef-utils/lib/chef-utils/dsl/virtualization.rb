#
# Copyright:: Copyright 2018-2020, Chef Software Inc.
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
    module Virtualization
      include Internal

      # Determine if the current node is running under KVM.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def kvm?(node = __getnode)
        node.dig("virtualization", "system") == "kvm"
      end

      # Determine if the current node is running in a linux container.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def lxc?(node = __getnode)
        node.dig("virtualization", "system") == "lxc"
      end

      #
      # Determine if the current node is running under Parallels Desktop.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running under Parallels Desktop, false
      #   otherwise
      #
      def parallels?(node = __getnode)
        node.dig("virtualization", "system") == "parallels"
      end

      # Determine if the current node is running under VirtualBox.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def vbox?(node = __getnode)
        node.dig("virtualization", "system") == "vbox"
      end

      alias_method :virtualbox?, :vbox?

      #
      # Determine if the current node is running under VMware.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def vmware?(node = __getnode)
        node.dig("virtualization", "system") == "vmware"
      end

      # Determine if the current node is running under openvz.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def openvz?(node = __getnode)
        node.dig("virtualization", "system") == "openvz"
      end

      # Determine if the current node is running under any virutalization environment
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def virtual?(node = __getnode)
        openvz?(node) || vmware?(node) || virtualbox?(node) || parallels?(node) || lxc?(node) || kvm?(node)
      end

      # Determine if the current node is NOT running under any virutalization environment
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def physical?(node = __getnode)
        !virtual?(node)
      end

      # Determine if the current node is running in vagrant mode.
      #
      # Note that this API is equivalent to just looking for the vagrant user or the
      # vagrantup.com domain in the hostname, which is the best API we have.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #   true if the machine is currently running vagrant, false
      #   otherwise
      #
      def vagrant?(node = __getnode)
        vagrant_key?(node) || vagrant_domain?(node) || vagrant_user?(node)
      end

      private

      # Check if the +vagrant+ key exists on the +node+ object. This key is no
      # longer populated by vagrant, but it is kept around for legacy purposes.
      #
      # @param (see vagrant?)
      # @return (see vagrant?)
      #
      def vagrant_key?(node = __getnode)
        node.key?("vagrant")
      end

      # Check if "vagrantup.com" is included in the node's domain.
      #
      # @param (see vagrant?)
      # @return (see vagrant?)
      #
      def vagrant_domain?(node = __getnode)
        node.key?("domain") && !node["domain"].nil? && node["domain"].include?("vagrantup.com")
      end

      # Check if the system contains a +vagrant+ user.
      #
      # @param (see vagrant?)
      # @return (see vagrant?)
      #
      def vagrant_user?(node = __getnode)
        !!(Etc.getpwnam("vagrant") rescue nil)
      end

      extend self
    end
  end
end
