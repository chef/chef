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
    module Windows
      require_relative "../version_string"

      include Internal

      # Determine if the current node is Windows Server Core.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.7
      #
      # @return [Boolean]
      #
      def windows_server_core?(node = __getnode)
        node["kernel"]["server_core"] == true
      end

      # Determine if the current node is Windows Workstation.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.7
      #
      # @return [Boolean]
      #
      def windows_workstation?(node = __getnode)
        node["kernel"]["product_type"] == "Workstation"
      end

      # Determine if the current node is Windows Server.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.7
      #
      # @return [Boolean]
      #
      def windows_server?(node = __getnode)
        node["kernel"]["product_type"] == "Server"
      end

      # Determine the current Windows NT version. The NT version often differs from the marketing version, but offers a good way to find desktop and server releases that are based on the same codebase. For example NT 6.3 corresponds to Windows 8.1 and Windows 2012 R2.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [ChefUtils::VersionString]
      #
      def windows_nt_version(node = __getnode)
        ChefUtils::VersionString.new(node["os_version"])
      end

      # Determine the installed version of PowerShell.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [ChefUtils::VersionString]
      #
      def powershell_version(node = __getnode)
        ChefUtils::VersionString.new(node["languages"]["powershell"]["version"])
      end

      extend self
    end
  end
end
