#
# Copyright:: Chef Software, Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class WindowsDefender < Chef::Resource
      unified_mode true
      provides :windows_defender

      description "Use the **windows_defender** resource to enable or disable the Microsoft Windows Defender service."
      introduced "17.3"
      examples <<~DOC
      **Configure Windows Defender AV settings**:

      ```ruby
      windows_defender 'Configure Defender' do
        realtime_protection true
        intrusion_protection_system true
        lock_ui true
        scan_archives true
        scan_scripts true
        scan_email true
        scan_removable_drives true
        scan_network_files false
        scan_mapped_drives false
        action :enable
      end
      ```

      **Disable Windows Defender AV**:

      ```ruby
      windows_defender 'Disable Defender' do
        action :disable
      end
      ```
      DOC

      # DisableIOAVProtection
      property :realtime_protection, [true, false],
        default: true,
        description: "Enable realtime scanning of downloaded files and attachments."

      # DisableIntrusionPreventionSystem
      property :intrusion_protection_system, [true, false],
        default: true,
        description: "Enable network protection against exploitation of known vulnerabilities."

      # UILockdown
      property :lock_ui, [true, false],
        description: "Lock the UI to prevent users from changing Windows Defender settings.",
        default: false

      # DisableArchiveScanning
      property :scan_archives, [true, false],
        default: true,
        description: "Scan file archives such as .zip or .gz archives."

      # DisableScriptScanning
      property :scan_scripts, [true, false],
        default: false,
        description: "Scan scripts in malware scans."

      # DisableEmailScanning
      property :scan_email, [true, false],
        default: false,
        description: "Scan e-mails for malware."

      # DisableRemovableDriveScanning
      property :scan_removable_drives, [true, false],
        default: false,
        description: "Scan content of removable drives."

      # DisableScanningNetworkFiles
      property :scan_network_files, [true, false],
        default: false,
        description: "Scan files on a network."

      # DisableScanningMappedNetworkDrivesForFullScan
      property :scan_mapped_drives, [true, false],
        default: true,
        description: "Scan files on mapped network drives."

      load_current_value do
        values = powershell_exec!("Get-MPpreference").result

        lock_ui values["UILockdown"]
        realtime_protection !values["DisableIOAVProtection"]
        intrusion_protection_system !values["DisableIntrusionPreventionSystem"]
        scan_archives !values["DisableArchiveScanning"]
        scan_scripts !values["DisableScriptScanning"]
        scan_email !values["DisableEmailScanning"]
        scan_removable_drives !values["DisableRemovableDriveScanning"]
        scan_network_files !values["DisableScanningNetworkFiles"]
        scan_mapped_drives !values["DisableScanningMappedNetworkDrivesForFullScan"]
      end

      action :enable do
        windows_service "Windows Defender" do
          service_name "WinDefend"
          action %i{start enable}
          startup_type :automatic
        end

        converge_if_changed do
          powershell_exec!(set_mppreference_cmd)
        end
      end

      action :disable do
        windows_service "Windows Defender" do
          service_name "WinDefend"
          action %i{disable stop}
        end
      end

      action_class do
        require "chef/mixin/powershell_type_coercions"
        include Chef::Mixin::PowershellTypeCoercions

        PROPERTY_TO_PS_MAP = {
          realtime_protection: "DisableIOAVProtection",
          intrusion_protection_system: "DisableIntrusionPreventionSystem",
          scan_archives: "DisableArchiveScanning",
          scan_scripts: "DisableScriptScanning",
          scan_email: "DisableEmailScanning",
          scan_removable_drives: "DisableRemovableDriveScanning",
          scan_network_files: "DisableScanningNetworkFiles",
          scan_mapped_drives: "DisableScanningMappedNetworkDrivesForFullScan",
        }.freeze

        def set_mppreference_cmd
          cmd = "Set-MpPreference -Force"
          cmd << " -UILockdown #{type_coercion(new_resource.lock_ui)}"

          # the values are the opposite in Set-MpPreference and our properties so we have to iterate
          # over the list and negate the provided values so it makes sense with the cmdlet flag's expected value
          PROPERTY_TO_PS_MAP.each do |prop, flag|
            next if new_resource.send(prop).nil? || current_resource.send(prop) == new_resource.send(prop)

            cmd << " -#{flag} #{type_coercion(!new_resource.send(prop))}"
          end
          cmd
        end
      end
    end
  end
end
