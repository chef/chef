#
# Cookbook:: end_to_end
# Recipe:: linux
#
# Copyright:: Copyright (c) Chef Software Inc.
#

hostname "chef-bk-ci.chef.io"

apt_update

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

include_recipe "::_yum" if platform_family?("rhel")

if platform_family?("rhel", "fedora", "amazon")
  include_recipe "selinux::disabled"
end

build_essential do
  raise_if_unsupported true
end

include_recipe "::_packages"

include_recipe "ntp"

include_recipe "resolver"

users_manage "sysadmin" do
  group_id 2300
  action [:create]
end

ssh_known_hosts_entry "github.com"

include_recipe "chef-client::delete_validation"
include_recipe "chef-client::config"
include_recipe "::_chef_client_trusted_certificate"

include_recipe "openssh"

include_recipe "nscd"

include_recipe "logrotate"

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

user_ulimit "tomcat" do
  filehandle_soft_limit 8192
  filehandle_hard_limit 8192
  process_soft_limit 61504
  process_hard_limit 61504
  memory_limit 1024
  core_limit 2048
  core_soft_limit 1024
  core_hard_limit "unlimited"
  stack_soft_limit 2048
  stack_hard_limit 2048
  rtprio_soft_limit 60
  rtprio_hard_limit 60
end

chef_client_cron "Run chef-client as a cron job"

chef_client_cron "Run chef-client with base recipe" do
  minute 0
  hour "0,12"
  job_name "chef-client-base"
  log_directory "/var/log/custom_chef_client_dir/"
  log_file_name "chef-client-base.log"
  daemon_options ["--override-runlist mycorp_base::default"]
end

chef_client_systemd_timer "Run chef-client as a systemd timer" do
  interval "1hr"
  cpu_quota 50
  nice 19
  cpu_scheduling_policy "idle"
  cpu_scheduling_priority 1
  io_scheduling_class "idle"
  io_scheduling_priority 7
  only_if { systemd? }
end

chef_client_systemd_timer "a timer that does not exist" do
  action :remove
end

locale "set system locale" do
  lang "en_US.UTF-8"
  only_if { debian? }
end

include_recipe "::_apt" if platform_family?("debian")
include_recipe "::_zypper" if suse?
include_recipe "::_chef-vault" unless includes_recipe?("end_to_end::chef-vault")
include_recipe "::_sudo"
include_recipe "::_sysctl"
include_recipe "::_alternatives"
include_recipe "::_cron"
include_recipe "::_ohai_hint"
include_recipe "::_openssl"
include_recipe "::_tests"
include_recipe "::_mount"

# at the moment these do not run properly in docker
# we need to investigate if this is a snap on docker issue or a chef issue
# include_recipe "::_snap" if platform?("ubuntu")
