#
# Cookbook:: end_to_end_arm
# Recipe:: _archive
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# archive_file only extracts archives, it doesn't create them. Build a small
# sample archive on the node first instead of shipping a prebuilt one that
# may fail to be delivered to the target.
#

archive_dir = "C:\\chef_arm_test\\archive"
sample_dir = "#{archive_dir}\\sample"
zip_path = "#{archive_dir}\\sample.zip"
extract_path = "#{archive_dir}\\extracted"

directory sample_dir do
  recursive true
end

file "#{sample_dir}\\hello.txt" do
  content "hello from the end_to_end_arm cookbook\n"
end

powershell_script "create sample zip archive" do
  code "Compress-Archive -Path \"#{sample_dir}\\*\" -DestinationPath \"#{zip_path}\" -Force"
  not_if { ::File.exist?(zip_path) }
end

archive_file "sample.zip" do
  path zip_path
  extract_to extract_path
end
