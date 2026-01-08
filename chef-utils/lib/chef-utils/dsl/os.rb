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
    module OS
      include Internal

      #
      # NOTE CAREFULLY: Most node['os'] values should not appear in this file at all.
      #
      # For cases where node['os'] == node['platform_family'] == node['platform'] then
      # only the platform helper should be added.
      #

      # Determine if the current node is Linux.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def linux?(node = __getnode)
        node["os"] == "linux"
      end

      # Determine if the current node is Darwin.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.5
      #
      # @return [Boolean]
      #
      def darwin?(node = __getnode)
        node["os"] == "darwin"
      end

      extend self
    end
  end
end
