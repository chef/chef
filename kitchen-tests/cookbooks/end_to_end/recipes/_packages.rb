#
# Cookbook:: end_to_end
# Recipe:: packages
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# this is just a list of package that exist on every O/S we test, and often aren't installed by default.  you don't
# have to get too clever here, you can delete packages if they don't exist everywhere we test.
pkgs = %w{lsof tcpdump strace zsh dmidecode ltrace bc curl wget subversion traceroute tmux }

# this deliberately calls the multipackage API N times in order to do one package installation in order to exercise the
# multipackage cookbook.
pkgs.each do |pkg|
  multipackage pkgs
end

# make sure customers can install knife back into the client for now
# and also make sure chef_gem works in general
gems = %w{knife community_cookbook_releaser}

gems.each do |gem|
  chef_gem gem do
    compile_time false
  end
end
