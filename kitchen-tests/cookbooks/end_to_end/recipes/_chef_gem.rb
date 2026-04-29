#
# Cookbook:: end_to_end
# Recipe:: chef_gem
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

gem_name = "community_cookbook_releaser"

chef_gem gem_name do
  action :install
  compile_time false
end

chef_gem "aws-sdk-ec2" do
  action :install
  compile_time false
end

# Install build tools required for compiling native gem extensions
build_pkgs = value_for_platform_family(
  "rhel" => %w[gcc make],
  "fedora" => %w[gcc make],
  "suse" => %w[gcc make],
  "amazon" => %w[gcc make]
)

package build_pkgs if build_pkgs

# Install MySQL/MariaDB client development headers for the mysql2 gem.
# RHEL 9+ replaced mariadb-devel with mariadb-connector-c-devel in AppStream.
mysql2_dev_pkg = value_for_platform_family(
  "debian" => "default-libmysqlclient-dev",
  "rhel" => node["platform_version"].to_i >= 9 ? "mariadb-connector-c-devel" : "mariadb-devel",
  "fedora" => "mariadb-devel",
  "suse" => "libmariadb-devel",
  "amazon" => node["platform_version"].to_i >= 2023 ? "mariadb105-devel" : "mariadb-devel"
)

package mysql2_dev_pkg if mysql2_dev_pkg

chef_gem "mysql2" do
  compile_time false
end
