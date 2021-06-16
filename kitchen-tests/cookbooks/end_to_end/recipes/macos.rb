#
# Cookbook:: end_to_end
# Recipe:: macos
#
# Copyright:: Copyright (c) Chef Software Inc.
#

chef_sleep "2"

execute "sleep 1"

execute "sleep 1 second" do
  command "sleep 1"
  live_stream true
end

execute "sensitive sleep" do
  command "sleep 1"
  sensitive true
end

timezone "America/Los_Angeles"

include_recipe "ntp"

resolver_config "/etc/resolv.conf" do
  nameservers [ "8.8.8.8", "8.8.4.4" ]
  search [ "chef.io" ]
end

users_from_databag = search("users", "*:*")

users_manage "remove sysadmin" do
  group_name "sysadmin"
  group_id 2300
  users users_from_databag
  action [:remove]
end

users_manage "create sysadmin" do
  group_name "sysadmin"
  group_id 2300
  users users_from_databag
  action [:create]
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

ssh_known_hosts_entry "github.com"

include_recipe "::_chef_client_config"
include_recipe "::_chef_client_trusted_certificate"

chef_client_launchd "Every 30 mins Infra Client run" do
  interval 30
  action :enable
end

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

osx_profile "Remove screensaver profile" do
  identifier "com.company.screensaver"
  action :remove
end

build_essential

launchd "io.chef.testing.fake" do
  source "io.chef.testing.fake.plist"
  action "enable"
end

homebrew_update "update" do
  action :update
end

homebrew_package "nethack"

homebrew_package "nethack" do
  action :purge
end

homebrew_cask "do-not-disturb"

include_recipe "::_dmg_package"
include_recipe "::_macos_userdefaults"
include_recipe "::_ohai_hint"
include_recipe "::_openssl"
