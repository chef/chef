#
# Cookbook:: webapp
# Recipe:: packages
#
# Copyright:: 2014-2017, Chef Software, Inc.
#

# this is just a list of package that exist on every O/S we test, and often aren't installed by default.  you don't
# have to get too clever here, you can delete packages if they don't exist everywhere we test.
pkgs = %w{lsof tcpdump strace zsh dmidecode ltrace bc curl wget telnet subversion git traceroute htop tmux }

# this deliberately calls the multipackage API N times in order to do one package installation in order to exercise the
# multipackage cookbook.
pkgs.each do |pkg|
  multipackage pkgs
end

gems = %w{fpm aws-sdk}

gems.each do |gem|
  chef_gem gem do
    compile_time false
  end
end
