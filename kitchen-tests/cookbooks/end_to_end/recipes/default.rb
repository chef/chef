#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

include_recipe "::linux" if linux?
include_recipe "::macos" if macos?
include_recipe "::windows" if windows?
