#
# Cookbook:: end_to_end
# Recipe:: packages
#
# Copyright:: Copyright (c) Chef Software Inc.
#

# this is just a list of package that exist on every O/S we test, and often aren't installed by default.  you don't
# have to get too clever here, you can delete packages if they don't exist everywhere we test.
# pkgs = %w{lsof tcpdump strace zsh dmidecode ltrace bc wget subversion traceroute tmux openssl}
pkgs = %w{lsof tcpdump strace zsh ltrace bc wget subversion traceroute tmux openssl}

package pkgs
