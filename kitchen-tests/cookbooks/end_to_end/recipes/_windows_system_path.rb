#
# Cookbook:: end_to_end
# Recipe:: _windows_system_path
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# Verifies that standard Windows system directories are present in the
# subprocess PATH so that system utilities can be invoked by relative name
# from powershell_script and execute resources.
#

# Verify PATH contains Windows system directories at recipe execution time.
ruby_block "verify System32 is in PATH" do
  block do
    path_entries = ENV["PATH"].split(";").map(&:downcase)
    system_root  = ENV.fetch("SystemRoot", 'C:\Windows').downcase
    required = ["#{system_root}\\system32", system_root]
    missing  = required.reject { |dir| path_entries.any? { |p| p == dir } }
    raise "Windows system directories missing from PATH: #{missing.join(", ")}" unless missing.empty?
  end
end

# Verify that native Windows system utilities work by relative name inside
# powershell_script. This is the core scenario — without the fix, these fail
# with "The term 'X' is not recognized as the name of a cmdlet..."
powershell_script "invoke ipconfig by relative name" do
  code <<~EOH
    $output = ipconfig
    if ($LASTEXITCODE -ne 0) {
      throw "ipconfig failed with exit code $LASTEXITCODE"
    }
    Write-Host "ipconfig succeeded: System32 is in PATH"
  EOH
  live_stream true
end

powershell_script "invoke cmd by relative name" do
  code <<~EOH
    $output = cmd.exe /c "echo PATH check passed"
    Write-Host $output
  EOH
  live_stream true
end

# Also verify via execute resource — confirms PATH is correct for all
# shell_out callers, not just powershell_script.
execute "invoke ipconfig via execute resource" do
  command "ipconfig"
  live_stream true
end
