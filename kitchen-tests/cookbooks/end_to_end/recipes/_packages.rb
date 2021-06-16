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
gem_name = rhel6? ? "community_cookbook_releaser" : "knife"

chef_gem gem_name do
  action :install
  compile_time false
end
