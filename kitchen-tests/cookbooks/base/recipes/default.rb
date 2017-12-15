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

include_recipe "build-essential"

include_recipe "::packages"

include_recipe "ntp"

include_recipe "resolver"

users_manage "sysadmin" do
  group_id 2300
  action [:create]
end

include_recipe "sudo"

include_recipe "chef-client::delete_validation"
include_recipe "chef-client::config"
include_recipe "chef-client"

include_recipe "chef-apt-docker"
include_recipe "chef-yum-docker"

# hack needed for debian-7 on docker
directory "/var/run/sshd"

include_recipe "openssh"

include_recipe "nscd"

include_recipe "logrotate"

include_recipe "cron"

include_recipe "git"

include_recipe "::tests"
