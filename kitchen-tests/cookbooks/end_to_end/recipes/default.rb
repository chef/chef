#
# Cookbook:: end_to_end
# Recipe:: default
#
# Copyright:: Copyright (c) Chef Software Inc.
#

include_recipe "::linux" if linux?
include_recipe "::macos" if macos?
include_recipe "::windows" if windows?
