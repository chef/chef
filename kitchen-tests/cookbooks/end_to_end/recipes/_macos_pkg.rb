#
# Cookbook:: end_to_end
# Recipe:: _macos_pkg
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

macos_pkg "osquery" do
  checksum   "1fea8ac9b603851d2e76c5fc73138a468a3075a3002c8cb1fd7fff53b889c4dd"
  package_id "io.osquery.agent"
  source     "https://pkg.osquery.io/darwin/osquery-5.8.2.pkg"
  action     :install
end
