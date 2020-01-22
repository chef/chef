#
# Copyright:: Copyright 2020, Chef Software Inc.
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
      include Internal

      # Determine if the current node is Windows Server Core.
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def windows_server_core?(node = __getnode)
        node["kernel"]["server_core"] == true
      end

      # Determine if the current node is Windows Workstation
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def windows_workstation?(node = __getnode)
        node["kernel"]["product_type"] == "Workstation"
      end

      # Determine if the current node is Windows Server
      #
      # @param [Chef::Node] node
      #
      # @return [Boolean]
      #
      def windows_server?(node = __getnode)
        node["kernel"]["product_type"] == "Server"
      end

      extend self
    end
  end
end
