#
# Cookbook:: end_to_end
# Recipe:: windows
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

# hostnames on windows cannot contain a '.'
# hostname on windows requires a reboot
# hostname "chef-bk-ci"

chef_sleep "2"

execute "dir"

execute "Print git version" do
  command "git --version & git --exec-path"
  live_stream true
end

# FIXME  Uninstall git using powershell
# this is a temporary band-aid due to the fallback git version in
# https://github.com/sous-chefs/git defaulting to an older version of git
# than will be installed on the current image this runs in for GitHub Actions
powershell_script "uninstall_git" do
  code <<-EOH
    $possibleInstalledPaths = @("C:/Program Files/Git/", "C:/Program Files (x64)/Git/", "c:/git/")
    $foundAnInstallation = $false
    ### For all places where Git "could" be.
    foreach ($installPath in $possibleInstalledPaths)
    {
      ### If the path where Git could exist
      if (Test-Path($installPath))
      {
        ## Some Git stuff might be running.. kill them.
        Stop-Process -processname Bash -erroraction 'silentlycontinue'
        Stop-Process -processname Putty* -erroraction 'silentlycontinue'

        $foundAnInstallation = $true
        Write-Host "Removing Git from " $installPath

        ### Find if there's an uninstaller in the folder.
        $uninstallers = Get-ChildItem $installPath"unins*.exe"

        ### In reality, there should only be just one that matches.
        foreach ($uninstaller in $uninstallers)
        {
           ### Invoke the uninstaller.
           $uninstallerCommandLineOptions = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /FORCECLOSEAPPLICATIONS"
           Start-Process -Wait -FilePath $uninstaller -ArgumentList $uninstallerCommandLineOptions
        }

        ### Remove the folder if it didn't clean up properly.
        if (Test-Path($installPath))
        {
           Remove-Item -Recurse -Force $installPath
        }
      }
    }

    if (!($foundAnInstallation))
    {
       Write-Host "No git installation found. Nothing to uninstall"
    }
  EOH
  live_stream true
end

powershell_script "sleep 1 second" do
  code "Start-Sleep -s 1"
  live_stream true
end

powershell_script "sleep 1 second inline" do
  code "Start-Sleep -s 1"
  use_inline_powershell true
end

powershell_script "ensure inline only_if guards work" do
  code "Start-Sleep -s 1"
  only_if "$True"
  use_inline_powershell true
end

powershell_script "ensure inline not_if guards work" do
  code "Start-Sleep -s 1"
  not_if "$False"
  use_inline_powershell true
end

powershell_script "sensitive sleep" do
  code "Start-Sleep -s 1"
  sensitive true
end

timezone "Pacific Standard time"

include_recipe "ntp"

windows_security_policy "NewGuestName" do
  secvalue "down_with_guests"
  action :set
end

windows_security_policy "EnableGuestAccount" do
  secvalue "1"
  action :set
end

windows_security_policy "LockoutBadCount" do
  secvalue "15"
  action :set
end

windows_security_policy "LockoutDuration" do
  secvalue "120"
  action :set
end

windows_security_policy "ResetLockoutCount" do
  secvalue "90"
  action :set
end

windows_firewall_profile "Domain" do
  default_inbound_action "Allow"
  default_outbound_action "Allow"
  action :enable
end

windows_firewall_profile "Public" do
  action :disable
end

%w{001 002 003}.each do |control|
  inspec_waiver_file_entry "fake_inspec_control_#{control}" do
    expiration "2025-07-01"
    justification "Waiving this control for the purposes of testing"
    action :add
  end
end

inspec_waiver_file_entry "fake_inspec_control_002" do
  action :remove
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

# FIXME: upstream users cookbooks is currently broken on windows
# users_from_databag = search("users", "*:*")
#
# users_manage "remove sysadmin" do
#   group_name "sysadmin"
#   group_id 2300
#   users users_from_databag
#   action [:remove]
# end
#
# # FIXME: create is not idempotent. it fails with a windows error if this already exists.
# users_manage "create sysadmin" do
#   group_name "sysadmin"
#   group_id 2300
#   users users_from_databag
#   action [:create]
# end

include_recipe "::_chef_client_config"
include_recipe "::_chef_client_trusted_certificate"

# test various archive formats in the archive_file resource
%w{tourism.tar.gz tourism.tar.xz tourism.zip}.each do |archive|
  cookbook_file File.join(Chef::Config[:file_cache_path], archive) do
    source archive
  end

  archive_file archive do
    path File.join(Chef::Config[:file_cache_path], archive)
    extract_to File.join(Chef::Config[:file_cache_path], archive.tr(".", "_"))
  end
end

locale "set system locale" do
  lang "en-us"
end

include_recipe "::_ohai_hint"

hostname "new-hostname" do
  windows_reboot false
end

user "phil" do
  uid "8019"
end

user "phil" do
  action :remove
end

directory "C:\\mordor" do
  rights :full_control, "everyone"
end

cookbook_file "c:\\mordor\\steveb-new.pfx" do
  source "/certs/steveb-new.pfx"
  action :create_if_missing
end

windows_certificate "c:/mordor/steveb-new.pfx" do
  pfx_password "1234"
  action :create
  user_store true
  store_name "MY"
end

cookbook_file "c:\\mordor\\ca.cert.pem" do
  source "/certs/ca.cert.pem"
  action :create_if_missing
end

windows_certificate "c:/mordor/ca.cert.pem" do
  store_name "ROOT"
end

include_recipe "::_habitat_win_config"
include_recipe "::_habitat_win_package"
include_recipe "::_habitat_win_service"
include_recipe "::_habitat_win_sup"
include_recipe "::_habitat_win_user_toml"
include_recipe "::_windows_printer"
include_recipe "::_windows_defender"

windows_update_settings "Disable Windows Update" do
  block_windows_update_website true
  disable_automatic_updates true
end

windows_feature_powershell "RSAT-AD-PowerShell" do
  action :install
end

include_recipe "::_chef_gem"
include_recipe "::_openssl"

# Exercise Habitat CA cert resource when Habitat-based Chef is present on Windows
if ::File.exist?("C:/ProgramData/Habitat/hab.exe")
  include_recipe "::_chef_client_hab_ca_cert"
end

include_recipe "git"
