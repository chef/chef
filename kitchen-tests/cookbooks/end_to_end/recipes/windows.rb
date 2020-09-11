#
# Cookbook:: end_to_end
# Recipe:: windows
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# hostnames on windows cannot contain a '.'
# hostname on windows requires a reboot
# hostname "chef-bk-ci"

chef_sleep "2"

execute "dir"

powershell_script "sleep 1 second" do
  code "Start-Sleep -s 1"
  live_stream true
end

powershell_script "sensitive sleep" do
  code "Start-Sleep -s 1"
  sensitive true
end

timezone "Pacific Standard time"

include_recipe "ntp"

windows_security_policy "EnableGuestAccount" do
  secoption "EnableGuestAccount"
  secvalue "1"
end

windows_firewall_profile "Domain" do
  default_inbound_action "Allow"
  default_outbound_action "Allow"
  action :enable
end

windows_user_privilege "BUILTIN\\Administrators" do
  privilege %w{SeAssignPrimaryTokenPrivilege SeIncreaseQuotaPrivilege}
  action :add
end

windows_firewall_profile "Public" do
  action :disable
end

users_manage "remove sysadmin" do
  group_name "sysadmin"
  group_id 2300
  action [:remove]
end

# FIXME: create is not idempotent. it fails with a windows error if this already exists.
users_manage "create sysadmin" do
  group_name "sysadmin"
  group_id 2300
  action [:create]
end

include_recipe "chef-client::delete_validation"
include_recipe "chef-client::config"
include_recipe "::_chef_client_trusted_certificate"

include_recipe "git"

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
  lang "en_US.UTF-8"
  only_if { debian? }
end

include_recipe "::_ohai_hint"

hostname "new-hostname" do
  windows_reboot false
end