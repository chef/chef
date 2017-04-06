#
# Cookbook:: webapp
# Recipe:: default
#
# Copyright:: 2014-2017, Chef Software, Inc.
#

hostname "chef-travis-ci.chef.io"

if node["platform_family"] == "debian"
  include_recipe "ubuntu"
  apt_update "packages"
end

if %w{rhel fedora}.include?(node["platform_family"])
  include_recipe "selinux::disabled"
end

yum_repository "epel" do
  enabled true
  description "Extra Packages for Enterprise Linux #{node['platform_version'].to_i} - $basearch"
  failovermethod "priority"
  gpgkey "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{node['platform_version'].to_i}"
  gpgcheck true
  mirrorlist "https://mirrors.fedoraproject.org/metalink?repo=epel-#{node['platform_version'].to_i}&arch=$basearch"
  only_if { node["platform_family"] == "rhel" && node["platform"] != "amazon" }
end

include_recipe "build-essential"

include_recipe "::packages"

include_recipe "ntp"

include_recipe "resolver"

include_recipe "users::sysadmins"

include_recipe "sudo"

include_recipe "chef-client::delete_validation"
include_recipe "chef-client::config"
include_recipe "chef-client"

# hack needed for debian-7 on docker
directory "/var/run/sshd"

include_recipe "openssh"

include_recipe "nscd"

include_recipe "logrotate"

include_recipe "::tests"
