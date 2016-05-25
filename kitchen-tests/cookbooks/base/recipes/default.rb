#
# Cookbook Name:: webapp
# Recipe:: default
#
# Copyright (C) 2014
#

hostname "chef-travis-ci.chef.io"

if node["platform_family"] == "debian"
  include_recipe "ubuntu"
  apt_update "packages"
end

if %w{rhel fedora}.include?(node["platform_family"])
  include_recipe "selinux::disabled"
end

if node["platform_family"] == "rhel"
  include_recipe "yum-epel"
end

include_recipe "build-essential"

include_recipe "#{cookbook_name}::packages"

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
