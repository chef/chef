#
# Cookbook:: end_to_end
# Recipe:: linux
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

# This line is causing the knife action to fail on Amazon Linux 2.
# timezone "America/Los_Angeles"

include_recipe "::_yum" if platform_family?("rhel")

if platform_family?("rhel", "fedora", "amazon")
  selinux_install "selinux"

  selinux_state "permissive" do
    action :permissive
  end

  user "se_map_test"

  selinux_user "se_map_test_u" do
    level "s0"
    range "s0"
    roles %w{sysadm_r staff_r}
  end

  selinux_login "se_map_test" do
    user "se_map_test_u"
    range "s0"
  end

  selinux_login "se_map_test" do
    action :delete
  end

  selinux_user "se_map_test_u" do
    action :delete
  end

  user "se_map_test" do
    action :remove
  end
end

build_essential do
  raise_if_unsupported true
end

include_recipe "::_packages"
include_recipe "::_chef_gem"

unless amazon? && node["platform_version"] >= "2023" # TODO: look into chrony service issue
  include_recipe value_for_platform(
    opensuseleap: { "default" => "ntp" },
    amazon: { "2" => "ntp" },
    oracle: { "<= 8" => "ntp" },
    centos: { "<= 8" => "ntp" },
    rhel: { "<= 8" => "ntp" },
    default: "chrony"
  )
end

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

# Install required packages for using ssh_known_hosts_entry on docker containers
package_name_by_platform = {
  "suse" => "ssh-tools",
  "rhel" => "openssh-clients",
  "fedora" => "openssh-clients",
  "amazon" => "openssh-clients",
  "debian" => "openssh-client",
}
package_name = package_name_by_platform[node["platform_family"]]
package "SSH tools with ssh-keyscan" do
  package_name package_name
  action :install
  only_if { package_name }
end

ssh_known_hosts_entry "github.com"

include_recipe "openssh"

logrotate_package "logrotate"

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

user_ulimit "tomcat" do
  as_soft_limit 65535
  as_hard_limit "unlimited"
  cpu_soft_limit 1024
  cpu_hard_limit 8096
  filehandle_soft_limit 8192
  filehandle_hard_limit 8192
  process_soft_limit 61504
  process_hard_limit 61504
  locks_limit 8192
  maxlogins_soft_limit 5
  maxlogins_hard_limit 10
  memory_limit 1024
  msgqueue_soft_limit 2048
  msgqueue_hard_limit 4096
  core_limit 2048
  core_soft_limit 1024
  core_hard_limit "unlimited"
  stack_soft_limit 2048
  stack_hard_limit 2048
  sigpending_soft_limit 2048
  sigpending_hard_limit 2048
  rss_soft_limit
  rss_hard_limit
  rtprio_soft_limit 60
  rtprio_hard_limit 60
end

include_recipe "::_chef_client_config"
include_recipe "::_chef_client_trusted_certificate"

chef_client_cron "Run chef-client as a cron job" do
  # Temporarily setting chef_binary_path for vagrant boxes using community test-kitchen
  # This allows recipes to run on both omnibus and habitat environments
  chef_binary_path "/opt/chef/bin/chef-client" if ::File.exist?("/opt/chef/bin/chef-client")
  not_if { amazon? && node["platform_version"] >= "2023" } # TODO: look into cron.d template file issue with resource
end

chef_client_cron "Run chef-client with base recipe" do
  # Temporarily setting chef_binary_path for vagrant boxes using community test-kitchen
  # This allows recipes to run on both omnibus and habitat environments
  chef_binary_path "/opt/chef/bin/chef-client" if ::File.exist?("/opt/chef/bin/chef-client")
  minute 0
  hour "0,12"
  job_name "chef-client-base"
  log_directory "/var/log/custom_chef_client_dir/"
  log_file_name "chef-client-base.log"
  daemon_options ["--override-runlist mycorp_base::default"]
  not_if { amazon? && node["platform_version"] >= "2023" } # TODO: look into cron.d template file issue with resource
end

chef_client_systemd_timer "Run chef-client as a systemd timer" do
  # Temporarily setting chef_binary_path for vagrant boxes using community test-kitchen
  # This allows recipes to run on both omnibus and habitat environments
  chef_binary_path "/opt/chef/bin/chef-client" if ::File.exist?("/opt/chef/bin/chef-client")
  interval "1hr"
  cpu_quota 50
  only_if { systemd? }
end

chef_client_systemd_timer "a timer that does not exist" do
  # Temporarily setting chef_binary_path for vagrant boxes using community test-kitchen
  # This allows recipes to run on both omnibus and habitat environments
  chef_binary_path "/opt/chef/bin/chef-client" if ::File.exist?("/opt/chef/bin/chef-client")
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
include_recipe "::_cron" unless amazon? && node["platform_version"] >= "2023" # TODO: look into cron.d template file issue with resource
include_recipe "::_ohai_hint"
include_recipe "::_openssl"
include_recipe "::_tests" # comment out if it generates UTF-8 error
include_recipe "::_mount"
include_recipe "::_ifconfig"
# TODO: re-enable when habitat recipes are fixed
# unless RbConfig::CONFIG["host_cpu"].eql?("aarch64") # Habitat supervisor doesn't support aarch64 yet
#   if ::File.exist?("/etc/systemd/system")
#     include_recipe "::_habitat_config"
#     include_recipe "::_habitat_install_no_user"
#     include_recipe "::_habitat_package"
#     include_recipe "::_habitat_service"
#     include_recipe "::_habitat_sup"
#     include_recipe "::_habitat_user_toml"
#   end
# end

include_recipe "::_snap" if platform?("ubuntu")

# Exercise Habitat CA cert resource when Habitat-based Chef is present
if ::File.exist?("/hab/bin/hab")
  include_recipe "::_chef_client_hab_ca_cert"
end
