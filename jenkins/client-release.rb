#!/usr/bin/env ruby


require 'bundler/setup'
require 'uber-s3'

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

def package_name(os_platform, os_version, chef_version, architecture, package_iteration = nil)
  arch_dir = if (architecture == 'i386')
               'i686/'
             else
               'x86_64/'
             end
  arch_file_ext = if (os_platform == 'centos')
                    arch_dir + '.rpm'
                  else
                    if (architecture == 'i386')
                      'i386.deb'
                    else
                      'amd64.deb'
                    end
                  end
  chef_filename = 'chef-full_' + chef_version
  if (!package_iteration.nil?)
    package_iteration = '-' + package_iteration.to_s
    chef_filename += package_iteration
  end
  case os_platform
  when 'debian'
    directorybase = 'debian-6.0.1-'
    chef_filename += '_'
  when 'ubuntu'
    directorybase = 'ubuntu-' + os_version + '-'
    chef_filename += '_'
  when 'centos'
    directorybase = 'el-' + os_version + '-'
    chef_filename += '.'
  end
  filename = directorybase + arch_dir + chef_filename + arch_file_ext
end

# os_list = ['debian', 'centos', 'ubuntu']
# arch_list = ['i386', 'x86_64']
# osversion_list = ['10.04', '5'] #made up versions, will differ across operating systems

# os_list.each do |os|
#   arch_list.each do |arch|
#     osversion_list.each do |osversion|
#       puts package_name(os, osversion, '10.12.0.rc.1', arch, 1)
#       puts package_name(os, osversion, '10.12.0.rc.1', arch)
#     end
#   end
# end

# ARGV = [filename, os_platform, os_version, chef_version, architecture, package_iteration]

package_iter = package_name(ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5])
package = package_name(ARGV[1], ARGV[2], ARGV[3], ARGV[4])

puts ARGV[0] + " => " + package_iter
puts ARGV[0] + " => " + package

s3 = UberS3.new({
  :access_key         => 'abc', #PLACEHOLDER
  :secret_access_key  => 'def', #PLACEHOLDER
  :bucket             => 'opscode-full-stack',
  :adapter            => :net_http
})

file = IO.read(ARGV[0])

s3.store(package_iter, file, :access => :public_read)
s3.store(package, file, :access => :public_read)

