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
    module Platform
      include Internal

      # NOTE: if you are adding new platform helpers they should all have the `_platform?` suffix.
      #       DO NOT add new short aliases without the suffix (they will be deprecated in the future)
      #       aliases here are mostly for backwards compatibility with chef-sugar and new ones are DISCOURAGED.
      #       generally there should be one obviously correct way to do things.

      # Determine if the current node is linux mint.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def linuxmint_platform?(node = __getnode)
        node["platform"] == "linuxmint"
      end
      # chef-sugar backcompat method
      alias_method :mint?, :linuxmint_platform?
      # chef-sugar backcompat method
      alias_method :linux_mint?, :linuxmint_platform?
      # chef-sugar backcompat method
      alias_method :linuxmint?, :linuxmint_platform?

      # Determine if the current node is Ubuntu.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def ubuntu_platform?(node = __getnode)
        node["platform"] == "ubuntu"
      end
      # chef-sugar backcompat method
      alias_method :ubuntu?, :ubuntu_platform?

      # Determine if the current node is Raspbian.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def raspbian_platform?(node = __getnode)
        node["platform"] == "raspbian"
      end
      # chef-sugar backcompat method
      alias_method :raspbian?, :raspbian_platform?

      # Determine if the current node is Debian.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def debian_platform?(node = __getnode)
        node["platform"] == "debian"
      end

      # Determine if the current node is Amazon Linux.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def amazon_platform?(node = __getnode)
        node["platform"] == "amazon"
      end

      # Determine if the current node is Red Hat Enterprise Linux.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def redhat_platform?(node = __getnode)
        node["platform"] == "redhat"
      end
      # chef-sugar backcompat method
      alias_method :redhat_enterprise?, :redhat_platform?
      # chef-sugar backcompat method
      alias_method :redhat_enterprise_linux?, :redhat_platform?
      # chef-sugar backcompat method
      alias_method :redhat?, :redhat_platform?

      # Determine if the current node is CentOS.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def centos_platform?(node = __getnode)
        node["platform"] == "centos"
      end
      # chef-sugar backcompat method
      alias_method :centos?, :centos_platform?

      # Determine if the current node is CentOS Stream.
      #
      # @param [Chef::Node] node the node to check
      # @since 17.0
      #
      # @return [Boolean]
      #
      def centos_stream_platform?(node = __getnode)
        if node["os_release"]
          node.dig("os_release", "name") == "CentOS Stream"
        else
          node.dig("lsb", "id") == "CentOSStream"
        end
      end

      # Determine if the current node is Oracle Linux.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def oracle_platform?(node = __getnode)
        node["platform"] == "oracle"
      end
      # chef-sugar backcompat method
      alias_method :oracle_linux?, :oracle_platform?
      # chef-sugar backcompat method
      alias_method :oracle?, :oracle_platform?

      # Determine if the current node is Scientific Linux.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def scientific_platform?(node = __getnode)
        node["platform"] == "scientific"
      end
      # chef-sugar backcompat method
      alias_method :scientific_linux?, :scientific_platform?
      # chef-sugar backcompat method
      alias_method :scientific?, :scientific_platform?

      # Determine if the current node is ClearOS.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def clearos_platform?(node = __getnode)
        node["platform"] == "clearos"
      end
      # chef-sugar backcompat method
      alias_method :clearos?, :clearos_platform?

      # Determine if the current node is Fedora.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def fedora_platform?(node = __getnode)
        node["platform"] == "fedora"
      end

      # Determine if the current node is Arch Linux
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def arch_platform?(node = __getnode)
        node["platform"] == "arch"
      end

      # Determine if the current node is Solaris2.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def solaris2_platform?(node = __getnode)
        node["platform"] == "solaris2"
      end

      # Determine if the current node is SmartOS.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def smartos_platform?(node = __getnode)
        node["platform"] == "smartos"
      end

      # Determine if the current node is OmniOS.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def omnios_platform?(node = __getnode)
        node["platform"] == "omnios"
      end
      # chef-sugar backcompat method
      alias_method :omnios?, :omnios_platform?

      # Determine if the current node is OpenIndiana.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def openindiana_platform?(node = __getnode)
        node["platform"] == "openindiana"
      end
      # chef-sugar backcompat method
      alias_method :openindiana?, :openindiana_platform?

      # Determine if the current node is AIX.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def aix_platform?(node = __getnode)
        node["platform"] == "aix"
      end

      # Determine if the current node is FreeBSD.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def freebsd_platform?(node = __getnode)
        node["platform"] == "freebsd"
      end

      # Determine if the current node is OpenBSD.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def openbsd_platform?(node = __getnode)
        node["platform"] == "openbsd"
      end

      # Determine if the current node is NetBSD.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def netbsd_platform?(node = __getnode)
        node["platform"] == "netbsd"
      end

      # Determine if the current node is DragonFly BSD.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def dragonfly_platform?(node = __getnode)
        node["platform"] == "dragonfly"
      end

      # Determine if the current node is macOS.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def macos_platform?(node = __getnode)
        node["platform"] == "mac_os_x"
      end
      # chef-sugar backcompat method
      alias_method :mac_os_x_platform?, :macos_platform?

      # Determine if the current node is Gentoo.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def gentoo_platform?(node = __getnode)
        node["platform"] == "gentoo"
      end

      # Determine if the current node is Slackware.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def slackware_platform?(node = __getnode)
        node["platform"] == "slackware"
      end

      # Determine if the current node is SuSE.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def suse_platform?(node = __getnode)
        node["platform"] == "suse"
      end

      # Determine if the current node is openSUSE.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def opensuse_platform?(node = __getnode)
        node["platform"] == "opensuse" || node["platform"] == "opensuseleap"
      end
      # chef-sugar backcompat method
      alias_method :opensuse?, :opensuse_platform?
      # chef-sugar backcompat method
      alias_method :opensuseleap_platform?, :opensuse_platform?
      # chef-sugar backcompat method
      alias_method :leap_platform?, :opensuse_platform?
      # NOTE: to anyone adding :tumbleweed_platform? - :[opensuse]leap_platform? should be false on tumbleweed, :opensuse[_platform]? should be true

      # Determine if the current node is Windows.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def windows_platform?(node = __getnode)
        node["platform"] == "windows"
      end

      extend self
    end
  end
end
