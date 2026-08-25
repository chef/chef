#
# Cookbook:: end_to_end_arm
# Recipe:: windows
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# A trimmed-down sampling of end_to_end style resource coverage aimed at a
# Windows ARM64 target. We are not trying to exercise CPU-specific behavior
# here, just show that a representative set of Chef resources converge
# cleanly. Unlike cookbooks/end_to_end, nothing in this cookbook depends on
# files being pre-staged under files/ or on external cookbooks/Habitat
# packages that may not ship ARM64 builds -- every test that needs a file
# creates that file itself first instead of assuming it is already there.
#

chef_sleep "2"

# The hab-launched chef-client process doesn't have C:\Windows\System32 on
# its PATH, so any built-in resource that shells out to a bare system
# utility name (net.exe for windows_security_policy, auditpol.exe for
# windows_audit_policy, etc.) fails with "not recognized" -- fix PATH once,
# here, for the whole converge instead of patching each resource as it's
# discovered.
ruby_block "ensure System32 is on PATH" do
  block do
    system32 = "#{ENV['SystemRoot']}\\System32"
    paths = ENV["PATH"].to_s.split(";")
    unless paths.any? { |p| p.casecmp(system32) == 0 }
      ENV["PATH"] = ([system32] + paths).join(";")
    end
  end
end

execute "dir"

powershell_script "sleep 1 second" do
  code "Start-Sleep -s 1"
  live_stream true
end

powershell_script "sleep 1 second inline" do
  code "Start-Sleep -s 1"
  use_inline_powershell true
end

powershell_script "ensure inline only_if guards work" do
  code "Start-Sleep -s 1"
  only_if "$True"
  use_inline_powershell true
end

powershell_script "ensure inline not_if guards work" do
  code "Start-Sleep -s 1"
  not_if "$False"
  use_inline_powershell true
end

powershell_script "sensitive sleep" do
  code "Start-Sleep -s 1"
  sensitive true
end

directory "C:\\chef_arm_test" do
  recursive true
end

include_recipe "::_misc"
include_recipe "::_security_policy"
include_recipe "::_certificates"
include_recipe "::_archive"
include_recipe "::_openssl"
include_recipe "::_chef_client"
