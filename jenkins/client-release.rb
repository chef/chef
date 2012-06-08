


require 'bundler/setup'

# Want to upload debian, ubuntu 10, ubuntu 11, centos 5, centos 6
# Input - S3 credentials, OS platform, OS version, architecture, Chef version, package iteration

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

def package_name(os_platform, os_version, chef_version, package_iteration, architecture)
    arch_dir = if (architecture == 'i386')
    	       	  'i686/'
	       else
		  'x86-64/'
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
    package_iteration = '-' + package_iteration.to_s
    case os_platform
    when 'debian'
    	 directorybase = 'debian-6.0.1-'
	 chef_filename = 'chef-full_' + chef_version + '_' + package_iteration + '_'
    when 'ubuntu'
    	directorybase = 'ubuntu-' + os_version + '-'
	chef_filename = 'chef-full_' + chef_version + package_iteration + '_'
    when 'centos'
    	directorybase = 'el-' + os_version + '-'
	chef_filename = 'chef-full-' + chef_version + package_iteration + '.'
    end
    filename = directorybase + arch_dir + chef_filename + arch_file_ext
end