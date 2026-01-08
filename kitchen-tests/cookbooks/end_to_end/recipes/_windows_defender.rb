#
# Cookbook:: end_to_end
# Recipe:: _windows_defender
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  process_paths "c:\\windows\\system32"
  action :add
end
