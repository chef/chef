#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright:: Copyright (c) Chef Software Inc.
#

hostname "chef-bk-ci.chef.io"

apt_update

chef_sleep "2"

timezone "UTC"

include_recipe "ubuntu" if platform?("ubuntu")

if platform_family?("rhel", "fedora", "amazon")
  include_recipe "selinux::disabled"
end

bash "disable yum metadata caching" do
  code <<-EOH
    echo http_caching=packages >> /etc/yum.conf
  EOH
  only_if { File.exist?("/etc/yum.conf") && File.readlines("/etc/yum.conf").grep(/http_caching=packages/).empty? }
end

yum_repository "epel" do
  enabled true
  description "Extra Packages for Enterprise Linux #{node["platform_version"].to_i} - $basearch"
  failovermethod "priority"
  gpgkey "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node["platform_version"].to_i}"
  gpgcheck true
  mirrorlist "https://mirrors.fedoraproject.org/metalink?repo=epel-#{node["platform_version"].to_i}&arch=$basearch"
  only_if { rhel? }
end

build_essential do
  raise_if_unsupported true
end

include_recipe "::packages"

include_recipe "ntp"

include_recipe "resolver"

users_manage "sysadmin" do
  group_id 2300
  action [:create]
end

ssh_known_hosts_entry "github.com"

sudo "sysadmins" do
  group ["sysadmin", "%superadmin"]
  nopasswd true
end

sudo "some_person" do
  nopasswd true
  user "some_person"
  commands ["/opt/chef/bin/chef-client"]
  env_keep_add %w{PATH RBENV_ROOT RBENV_VERSION}
end

include_recipe "chef-client::delete_validation"
include_recipe "chef-client::config"

include_recipe "openssh"

include_recipe "nscd"

include_recipe "logrotate"

include_recipe "git"

directory "/etc/ssl"

cron_access "bob"

cron "some random cron job" do
  minute  0
  hour    23
  command "/usr/bin/true"
end

cron_d "another random cron job" do
  minute  0
  hour    23
  command "/usr/bin/true"
end

# Generate new key and certificate
openssl_dhparam "/etc/ssl/dhparam.pem" do
  key_length 1024
  action :create
end

# Generate new key with aes-128-cbc cipher
openssl_rsa_private_key "/etc/ssl/rsakey_aes128cbc.pem" do
  key_length 1024
  key_cipher "aes-128-cbc"
  action :create
end

openssl_rsa_public_key "/etc/ssl/rsakey_aes128cbc.pub" do
  private_key_path "/etc/ssl/rsakey_aes128cbc.pem"
  action :create
end

# test various archive formats in the archive_file resource
%w{tourism.tar.gz tourism.tar.xz tourism.zip}.each do |archive|
  cookbook_file File.join(Chef::Config[:file_cache_path], archive) do
    source archive
  end

  archive_file archive do
    path File.join(Chef::Config[:file_cache_path], archive)
    extract_to File.join(Chef::Config[:file_cache_path], archive.tr(".", "_"))
  end

  archive_file "distant_tourism.tar.gz" do
    url "https://github.com/chef/cookstyle/archive/v6.3.5.tar.gz"
    checksum "4692955a785990423c856ce809063d230cc96672d2092871bf1e66735bd6edd5"
    path File.join(Chef::Config[:file_cache_path], "distant_tourism.tar.gz")
    extract_to File.join(Chef::Config[:file_cache_path], "distant_tourism")
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
  only_if { systemd? }
end

include_recipe "::chef-vault" unless includes_recipe?("end_to_end::chef-vault")
include_recipe "::alternatives"
include_recipe "::tests"
