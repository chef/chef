#
# Cookbook:: end_to_end
# Recipe:: _macos_pkg
#
# Copyright:: Copyright (c) Chef Software Inc.
#

macos_pkg "osquery" do
  checksum   "7d0f97d0d4b463fcf03abedbf58939c900f310c214fd2fa3c28b1a848dcbffd9"
  package_id "io.osquery.agent"
  source     "https://pkg.osquery.io/darwin/osquery-5.11.0.pkg"
  action     :install
end
