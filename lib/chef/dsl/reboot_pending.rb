# Author:: Bryan McLellan <btm@loftninjas.org>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Copyright:: Copyright (c) 2011,2014, Chef Software, Inc.
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

require 'chef/dsl/platform_introspection'
require 'chef/dsl/registry_helper'

class Chef
  module DSL
    module RebootPending

      include Chef::DSL::RegistryHelper
      include Chef::DSL::PlatformIntrospection

      # Returns true if the system needs a reboot or is expected to reboot
      # Raises UnsupportedPlatform if this functionality isn't provided yet
      def reboot_pending?

        if platform?("windows")
          # PendingFileRenameOperations contains pairs (REG_MULTI_SZ) of filenames that cannot be updated
          # due to a file being in use (usually a temporary file and a system file)
          # \??\c:\temp\test.sys!\??\c:\winnt\system32\test.sys
          # http://technet.microsoft.com/en-us/library/cc960241.aspx
          registry_value_exists?('HKLM\SYSTEM\CurrentControlSet\Control\Session Manager', { :name => 'PendingFileRenameOperations' }) ||

          # RebootRequired key contains Update IDs with a value of 1 if they require a reboot.
          # The existence of RebootRequired alone is sufficient on my Windows 8.1 workstation in Windows Update
          registry_key_exists?('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') ||

          # Vista + Server 2008 and newer may have reboots pending from CBS
          registry_key_exists?('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootRequired') ||

          # The mere existance of the UpdateExeVolatile key should indicate a pending restart for certain updates
          # http://support.microsoft.com/kb/832475
          (registry_key_exists?('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile') &&
                !registry_get_values('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile').select { |v| v[:name] == "Flags" }[0].nil? &&
                [1,2,3].include?(registry_get_values('HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile').select { |v| v[:name] == "Flags" }[0][:data]))
        elsif platform?("ubuntu")
          # This should work for Debian as well if update-notifier-common happens to be installed. We need an API for that.
          File.exists?('/var/run/reboot-required')
        else
          raise Chef::Exceptions::UnsupportedPlatform.new(node[:platform])
        end
      end
    end
  end
end
