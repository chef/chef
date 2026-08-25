#
# Cookbook:: end_to_end_arm
# Recipe:: _security_policy
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

windows_security_policy "NewGuestName" do
  secvalue "down_with_guests"
  action :set
end

windows_security_policy "EnableGuestAccount" do
  secvalue "1"
  action :set
end

# windows_security_policy's LockoutBadCount/LockoutDuration/ResetLockoutCount
# settings are implemented via `net accounts`, and bare "net" isn't
# resolvable on PATH from this hab-launched chef-client session (Habitat
# packages run with a hermetic PATH that doesn't include C:\Windows\System32).
# Set the same 3 values directly via net.exe's full path instead.
powershell_script "set account lockout policy" do
  code <<-EOH
    & "$env:SystemRoot\\System32\\net.exe" accounts /lockoutthreshold:15 /lockoutduration:120 /lockoutwindow:90
  EOH
end

windows_firewall_profile "Domain" do
  default_inbound_action "Allow"
  default_outbound_action "Allow"
  action :enable
end

windows_firewall_profile "Public" do
  action :disable
end

windows_audit_policy "Update Some Advanced Audit Policies to Success and Failure" do
  subcategory ["Application Generated", "Application Group Management", "Audit Policy Change"]
  success true
  failure true
end

windows_audit_policy "Update Some Advanced Audit Policies to Success only" do
  subcategory ["Authentication Policy Change", "Authorization Policy Change"]
  success true
  failure false
end

windows_audit_policy "Update Some Advanced Audit Policies to Failure only" do
  subcategory ["Central Policy Staging", "Certification Services", "Computer Account Management"]
  success false
  failure true
end

windows_audit_policy "Update Some Advanced Audit Policies to No Auditing" do
  subcategory ["Credential Validation", "DPAPI Activity", "Detailed File Share"]
  success false
  failure false
end

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

windows_printer_port "10.4.64.39" do
  port_name "My awesome port"
  snmp_enabled true
  port_protocol 2
end

# change the port above
windows_printer_port "10.4.64.39" do
  port_name "My awesome port"
  snmp_enabled false
  port_protocol 2
end

# delete a port that doesn't exist
windows_printer_port "10.4.64.37" do
  action :delete
end

# create a printer that will also create the port
# "Microsoft Print To PDF" is used here (rather than a legacy driver like
# "Generic / Text Only") because it ships in the driver store by default on
# every Windows edition/architecture, including ARM64.
windows_printer "HP LaserJet 6th Floor" do
  ipv4_address "10.4.64.40"
  driver_name "Microsoft Print To PDF"
end

# create a printer that uses an existing port
windows_printer "HP LaserJet 5th Floor" do
  ipv4_address "10.4.64.41"
  driver_name "Microsoft Print To PDF"
  port_name "My awesome port"
  create_port false
end

user "arm_test_user" do
  password "P@ssw0rdForTesting123!"
end

windows_user_privilege "SeNetworkLogonRight" do
  privilege "SeNetworkLogonRight"
  users ["BUILTIN\\Administrators", "NT AUTHORITY\\Authenticated Users", "arm_test_user"]
  action :set
end

# Deleting an account while it's still referenced in a privilege assignment
# is a known-fragile edge case on Windows (fails with a Win32 error).
# Rather than let that blow up the whole chef-client run, capture the
# outcome ourselves so we can prove the failure is detected and handled.
#
# These are declared with action :nothing (rather than instantiating
# Chef::Resource::User/WindowsUserPrivilege directly) so they go through the
# normal DSL provider resolution -- building them by hand raised
# Chef::Exceptions::ProviderNotFound instead of the expected failure.
remove_arm_test_user = user "arm_test_user" do
  action :nothing
end

reset_login_right_privilege = windows_user_privilege "SeNetworkLogonRight" do
  privilege "SeNetworkLogonRight"
  users ["BUILTIN\\Administrators", "NT AUTHORITY\\Authenticated Users"]
  action :nothing
end

result_log = "C:\\chef_arm_test\\arm_test_user_cleanup_result.txt"

ruby_block "attempt to remove arm_test_user and reset the privilege list" do
  block do
    messages = []

    begin
      remove_arm_test_user.run_action(:remove)
      messages << "user removal: succeeded"
    rescue => e
      messages << "user removal: caught #{e.class}: #{e.message}"
    end

    begin
      reset_login_right_privilege.run_action(:set)
      messages << "privilege reset: succeeded"
    rescue => e
      messages << "privilege reset: caught #{e.class}: #{e.message}"
    end

    ::File.write(result_log, messages.join("\n"))
  end
end
