# frozen_string_literal: true
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

      # Determine if the current node is a KVM guest.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def kvm?(node = __getnode)
        node.dig("virtualization", "system") == "kvm" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is a KVM host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def kvm_host?(node = __getnode)
        node.dig("virtualization", "system") == "kvm" && node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is running in a linux container.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def lxc?(node = __getnode)
        node.dig("virtualization", "system") == "lxc" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is a linux container host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def lxc_host?(node = __getnode)
        node.dig("virtualization", "system") == "lxc" && node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is running under Parallels Desktop.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #   true if the machine is currently running under Parallels Desktop, false
      #   otherwise
      #
      def parallels?(node = __getnode)
        node.dig("virtualization", "system") == "parallels" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is a Parallels Desktop host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #   true if the machine is currently running under Parallels Desktop, false
      #   otherwise
      #
      def parallels_host?(node = __getnode)
        node.dig("virtualization", "system") == "parallels" && node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is a VirtualBox guest.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def vbox?(node = __getnode)
        node.dig("virtualization", "system") == "vbox" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is a VirtualBox host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def vbox_host?(node = __getnode)
        node.dig("virtualization", "system") == "vbox" && node.dig("virtualization", "role") == "host"
      end

      # chef-sugar backcompat method
      alias_method :virtualbox?, :vbox?

      # Determine if the current node is a VMWare guest.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def vmware?(node = __getnode)
        node.dig("virtualization", "system") == "vmware" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is VMware host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def vmware_host?(node = __getnode)
        node.dig("virtualization", "system") == "vmware" && node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is virtualized on VMware Desktop (Fusion/Player/Workstation).
      #
      # @param [Chef::Node] node
      # @since 17.9
      #
      # @return [Boolean]
      #
      def vmware_desktop?(node = __getnode)
        node.dig("virtualization", "system") == "vmware" && node.dig("vmware", "host", "type") == "vmware_desktop"
      end

      # Determine if the current node is virtualized on VMware vSphere (ESX).
      #
      # @param [Chef::Node] node
      # @since 17.9
      #
      # @return [Boolean]
      #
      def vmware_vsphere?(node = __getnode)
        node.dig("virtualization", "system") == "vmware" && node.dig("vmware", "host", "type") == "vmware_vsphere"
      end

      # Determine if the current node is an openvz guest.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def openvz?(node = __getnode)
        node.dig("virtualization", "system") == "openvz" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is an openvz host.
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def openvz_host?(node = __getnode)
        node.dig("virtualization", "system") == "openvz" && node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is running under Microsoft Hyper-v.
      #
      # @param [Chef::Node] node
      # @since 18.5
      #
      # @return [Boolean]
      #
      def hyperv?(node = __getnode)
        node.dig("virtualization", "system") == "hyperv" && node.dig("virtualization", "role") == "guest"
      end

      # Determine if the current node is running under any virtualization environment
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def guest?(node = __getnode)
        node.dig("virtualization", "role") == "guest"
      end

      # chef-sugar backcompat method
      alias_method :virtual?, :guest?

      # Determine if the current node supports running guests under any virtualization environment
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def hypervisor?(node = __getnode)
        node.dig("virtualization", "role") == "host"
      end

      # Determine if the current node is NOT running under any virtualization environment (bare-metal or hypervisor on metal)
      #
      # @param [Chef::Node] node
      # @since 15.8
      #
      # @return [Boolean]
      #
      def physical?(node = __getnode)
        !virtual?(node)
      end

      # Determine if the current node is running as a vagrant guest.
      #
      # Note that this API is equivalent to just looking for the vagrant user or the
      # vagrantup.com domain in the hostname, which is the best API we have.
      #
      # @param [Chef::Node] node
      # @since 15.8
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
