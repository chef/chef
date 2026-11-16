#
# Cookbook:: end_to_end
# Recipe:: packages
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

# this is just a list of package that exist on every O/S we test, and often aren't installed by default.  you don't
# have to get too clever here, you can delete packages if they don't exist everywhere we test.
pkgs = %w{lsof tcpdump strace zsh dmidecode bc wget subversion traceroute tmux openssl}

# ltrace is x86_64-only; no aarch64 package exists on Debian/Ubuntu
pkgs << "ltrace" if node["kernel"]["machine"] == "x86_64"

package pkgs
