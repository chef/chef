#
# Cookbook:: end_to_end
# Recipe:: _zypper
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

zypper_repository "nginx repo" do
  baseurl "https://nginx.org/packages/sles/15"
  gpgkey "https://nginx.org/keys/nginx_signing.key"
end

zypper_package "nginx"
