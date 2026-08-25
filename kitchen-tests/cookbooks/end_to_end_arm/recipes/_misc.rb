#
# Cookbook:: end_to_end_arm
# Recipe:: _misc
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#


# NOTE: the built-in `timezone` resource is intentionally not exercised here.
# Its load_current_resource step shells out to `tzutil /g` just to read the
# current timezone, and that call fails outright on this Windows ARM64 box
# (RuntimeError: There was an error running the tzutil command) -- not
# essential to the "sampling of things working" goal, so it's dropped rather
# than chased further.

# NOTE: the built-in `hostname` resource is intentionally not exercised here.
# On this chef-client/ruby combination it calls Socket.gethostbyname, which
# emits a deprecation warning to stderr; under the WinRM transport's
# `$ErrorActionPreference = 'Stop'` wrapper that stderr write is treated as a
# fatal NativeCommandError and silently kills chef-client mid-converge.

user "phil" do
  uid "8019"
end

user "phil" do
  action :remove
end

locale "set system locale" do
  lang "en-us"
end

%w{001 002 003}.each do |control|
  inspec_waiver_file_entry "fake_inspec_control_#{control}" do
    expiration "2027-07-01"
    justification "Waiving this control for the purposes of testing"
    action :add
  end
end

inspec_waiver_file_entry "fake_inspec_control_002" do
  action :remove
end

ohai_hint "hint_at_compile_time"

ohai_hint "not_at_compile_time" do
  compile_time false
end

ohai_hint "hint_with_content" do
  content Hash[:a, "test_content"]
end

ohai_hint "hint_without_content"

ohai_hint "hint_with_json_in_resource_name.json"

chef_gem "community_cookbook_releaser" do
  action :install
  compile_time false
end
