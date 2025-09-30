#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright © 2008-2025 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

include_recipe "::linux" if linux?
include_recipe "::macos" if macos?
include_recipe "::windows" if windows?
include_recipe "::freebsd" if freebsd?
