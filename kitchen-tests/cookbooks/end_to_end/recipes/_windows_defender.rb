#
# Cookbook:: end_to_end
# Recipe:: _windows_defender
#
# Copyright:: Copyright (c) Chef Software Inc.
#

windows_defender "Configure Windows Defender" do
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

windows_defender_exclusion "Exclude PNG files" do
  extensions "png"
  process_paths 'c:\\windows\\system32'
  action :add
end
