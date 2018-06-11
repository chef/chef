#
# Cookbook:: base
# Recipe:: default
#
# Copyright:: 2014-2017, Chef Software, Inc.
#

hostname "chef-travis-ci.chef.io"

apt_update

include_recipe "ubuntu" if platform?("ubuntu")

if platform_family?("rhel", "fedora", "amazon")
  include_recipe "selinux::disabled"
end

yum_repository "epel" do
  enabled true
  description "Extra Packages for Enterprise Linux #{node['platform_version'].to_i} - $basearch"
  failovermethod "priority"
  gpgkey "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
  gpgcheck true
  mirrorlist "https://mirrors.fedoraproject.org/metalink?repo=epel-#{node['platform_version'].to_i}&arch=$basearch"
  only_if { platform_family?("rhel") }
end

build_essential

include_recipe "::packages"

include_recipe "ntp"

include_recipe "resolver"

users_manage "sysadmin" do
  group_id 2300
  action [:create]
end

ssh_known_hosts_entry "github.com"
ssh_known_hosts_entry "travis.org"

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
include_recipe "chef-client"

include_recipe "openssh"

include_recipe "nscd"

include_recipe "logrotate"

include_recipe "cron"

include_recipe "git"

directory "/etc/ssl"

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

include_recipe "::tests"
