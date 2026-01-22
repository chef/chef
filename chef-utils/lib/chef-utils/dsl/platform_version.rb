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
    module PlatformVersion
      include Internal

      # Return the platform_version for the node. Acts like a String
      # but also provides a mechanism for checking version constraints.
      #
      # @param [Chef::Node] node the node to check
      # @since 15.8
      #
      # @return [ChefUtils::VersionString]
      #
      def platform_version(node = __getnode)
        ChefUtils::VersionString.new(node["platform_version"])
      end

      extend self
    end
  end
end
