#
# Cookbook:: end_to_end
# Recipe:: _macos_pkg
#
# Copyright:: Copyright (c) Chef Software Inc.
#

macos_pkg "osquery" do
  checksum   "a01d1f7da016f1e6bed54955e97982d491b7e55311433ff0fc985269160633af"
  package_id "io.osquery.agent"
  source     "https://pkg.osquery.io/darwin/osquery-5.10.2.pkg"
  action     :install
end
