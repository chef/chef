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

# Install build tools required for compiling native gem extensions.
# Debian: build-essential provides gcc, g++, make, binutils, libc-dev.
# RHEL/etc: gcc alone isn't enough — glibc-devel provides the C stdlib headers
# that mkmf needs to compile even a trivial test program.
build_pkgs = value_for_platform_family(
  "debian" => %w[build-essential],
  "rhel" => %w[gcc make glibc-devel],
  "fedora" => %w[gcc make glibc-devel],
  "suse" => %w[gcc make],
  "amazon" => %w[gcc make glibc-devel]
)

package build_pkgs if build_pkgs

# Debug: report compiler and header state before attempting gem install
execute "debug-mysql2-build-env-before" do
  command "echo '--- mysql2 build env ---' && " \
          "(which gcc && gcc --version | head -1) || echo 'gcc not found' && " \
          "echo 'mysql headers:' && find /usr/include -name 'mysql.h' 2>/dev/null || true"
  action :run
  live_stream true
end

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

# Debug: confirm headers are present and mysql_config works after package install
execute "debug-mysql2-build-env-after" do
  command "echo '--- mysql2 headers after install ---' && " \
          "find /usr/include -name 'mysql.h' 2>/dev/null || echo 'still no mysql.h' && " \
          "(mysql_config --cflags --libs 2>/dev/null || mariadb_config --cflags --libs 2>/dev/null || echo 'no mysql_config/mariadb_config') && " \
          "echo 'rpm/dpkg installed:' && " \
          "(rpm -qa 2>/dev/null | grep -Ei 'gcc|glibc-devel|mariadb|mysql' || dpkg -l 2>/dev/null | grep -Ei 'gcc|build-essential|libmariadb|libmysql' || true)"
  action :run
  live_stream true
end

chef_gem "mysql2" do
  compile_time false
end
