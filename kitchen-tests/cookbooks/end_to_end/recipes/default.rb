#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright:: 2014-2018, Chef Software, Inc.
#

hostname "chef-travis-ci.chef.io"

apt_update

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

include_recipe "git"

directory "/etc/ssl"

cron_access "bob"

cron_d "some random cron job" do
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
end

include_recipe "::tests"
