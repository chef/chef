#
# Cookbook:: end_to_end
# Recipe:: freebsd
#
# Copyright:: Copyright (c) Chef Software Inc.
#

hostname "chef-bk-ci.chef.io"

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

build_essential do
  raise_if_unsupported true
end

include_recipe "::_chef_gem"

include_recipe "ntp"

resolver_config "/etc/resolv.conf" do
  nameservers [ "8.8.8.8", "8.8.4.4" ]
  search [ "chef.io" ]
  atomic_update false # otherwise EBUSY for linux docker containers
end

users_from_databag = search("users", "*:*")

users_manage "sysadmin" do
  group_id 2300
  users users_from_databag
  action [:create]
end

ssh_known_hosts_entry "github.com"

include_recipe "openssh"

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

include_recipe "::_chef_client_config"
include_recipe "::_chef_client_trusted_certificate"

chef_client_cron "Run chef-client as a cron job"

chef_client_cron "Run chef-client with base recipe" do
  minute 0
  hour "0,12"
  job_name "chef-client-base"
  log_directory "/var/log/custom_chef_client_dir/"
  log_file_name "chef-client-base.log"
  daemon_options ["--override-runlist mycorp_base::default"]
end

include_recipe "::_chef-vault" unless includes_recipe?("end_to_end::chef-vault")
include_recipe "::_sudo"
include_recipe "::_cron"
include_recipe "::_ohai_hint"
include_recipe "::_openssl"
include_recipe "::_ifconfig"
# TODO: re-enable when habitat recipes are fixed
unless RbConfig::CONFIG["host_cpu"].eql?("aarch64") # Habitat supervisor doesn't support aarch64 yet
  if ::File.exist?("/etc/systemd/system")
    include_recipe "::_habitat_config"
    include_recipe "::_habitat_install_no_user"
    include_recipe "::_habitat_package"
    include_recipe "::_habitat_service"
    include_recipe "::_habitat_sup"
    include_recipe "::_habitat_user_toml"
  end
end
