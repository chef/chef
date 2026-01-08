#
# Author:: Adam Jacob (<adam@chef.io>)
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

require "chef-utils" unless defined?(ChefUtils::CANARY)
require_relative "../mixin/powershell_exec"

class Chef
  class Platform

    class << self
      include Chef::Mixin::PowershellExec

      def windows?
        ChefUtils.windows?
      end

      # @deprecated Windows Nano is not a thing anymore so this check shouldn't be used
      def windows_nano_server?
        false
      end

      # @deprecated we added this method due to Windows Server Nano, which is no longer a platform
      def supports_msi?
        return false unless windows?

        true
      end

      # @deprecated we don't support any release of Windows that isn't PS 3+
      def supports_powershell_execution_bypass?(node)
        true
      end

      def supports_dsc?(node)
        node[:languages] && node[:languages][:powershell] &&
          node[:languages][:powershell][:version].to_i >= 4
      end

      def supports_dsc_invoke_resource?(node)
        supports_dsc?(node) &&
          supported_powershell_version?(node, "5.0.10018.0")
      end

      def supports_refresh_mode_enabled?(node)
        supported_powershell_version?(node, "5.0.10586.0")
      end

      def dsc_refresh_mode_disabled?(node)
        exec = powershell_exec!("Get-DscLocalConfigurationManager")
        exec.error!
        exec.result["RefreshMode"] == "Disabled"
      end

      def supported_powershell_version?(node, version_string)
        return false unless node[:languages] && node[:languages][:powershell]

        require "rubygems" unless defined?(Gem)
        Gem::Version.new(node[:languages][:powershell][:version]) >=
          Gem::Version.new(version_string)
      end

    end
  end
end
