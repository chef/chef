#!/usr/bin/env ruby


require 'bundler/setup'
require 'uber-s3'
require 'ohai'

# Want to upload debian, ubuntu 10, ubuntu 11, centos 5, centos 6
# Input - filename, S3 credentials, OS platform, OS version, architecture, Chef version, package iteration

# debian:
# http://opscode-full-stack.s3.amazonaws.com/debian-6.0.1-i686/chef-full_0.10.10-1_i386.deb
# http://opscode-full-stack.s3.amazonaws.com/debian-6.0.1-x86_64/chef-full_0.10.10-1_amd64.deb

# centos 5:
# http://opscode-full-stack.s3.amazonaws.com/el-5.7-i686/chef-full-10.12.0.rc.1-1.i686.rpm
# http://opscode-full-stack.s3.amazonaws.com/el-5.7-x86_64/chef-full-10.12.0.rc.1-1.x86_64.rpm

# centos 6:
# http://opscode-full-stack.s3.amazonaws.com/el-6.2-i686/chef-full-10.12.0.rc.1-1.i686.rpm
# http://opscode-full-stack.s3.amazonaws.com/el-6.2-x86_64/chef-full-10.12.0.rc.1-1.x86_64.rpm

# ubuntu 10.04:
# http://opscode-full-stack.s3.amazonaws.com/ubuntu-10.04-i686/chef-full_10.12.0.rc.1-1_i386.deb
# http://opscode-full-stack.s3.amazonaws.com/ubuntu-10.04-x86_64/chef-full_10.12.0.rc.1-1_amd64.deb

# ubuntu 11.04:
# http://opscode-full-stack.s3.amazonaws.com/ubuntu-11.04-i686/chef-full_10.12.0.rc.1-1_i386.deb
# http://opscode-full-stack.s3.amazonaws.com/ubuntu-11.04-x86_64/chef-full_10.12.0.rc.1-1_amd64.deb

# This will take in data about the OS, chef, and architecture and spit out the proper upload directory
def package_name(filepath, os_platform, os_version, architecture)
  filename = filepath.split("/")[-1]
  arch_dir = if (architecture == 'i386')
               'i686/'
             else
               'x86_64/'
             end
  case os_platform
  when 'debian'
    directorybase = 'debian-6.0.1-'
  when 'ubuntu'
    directorybase = 'ubuntu-' + os_version + '-'
  when 'centos'
    directorybase = 'el-' + os_version + '-'
  end
  packagename = directorybase + arch_dir + filename
end

# os_list = ['debian', 'centos', 'ubuntu']
# arch_list = ['i386', 'x86_64']
# os_version = ['10.04', '6.2']

# os_list.each do |os|
#   arch_list.each do |arch|
#     os_version.each do |osversion|
#       puts package_name("/foo/bar/foobar/madeup.file", os, osversion, arch)
#       end
#   end
# end

# ARGV = [filepath, os_platform, os_version, architecture, credentials]

o = Ohai::System.new
o.require_plugin('os')
o.require_plugin('platform')
o.require_plugin('linux/cpu') if o.os == 'linux'

package = package_name(ARGV[0], o['platform'], o['platform_version'], o['kernel']['machine']) # format upload directory

(key, secret, bucket) = IO.read(ARGV[1]).lines.to_a  # Read in s3 credentials

s3 = UberS3.new({
  :access_key         => key.chomp,
  :secret_access_key  => secret.chomp,
  :bucket             => bucket.chomp,
  :adapter            => :net_http
})

file = IO.read(ARGV[0])

s3.store(package, file, :access => :public_read)
