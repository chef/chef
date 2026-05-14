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

# Native gem compilation test — validates the RELR fix.
# mysql2 requires linking against libruby.so; on systems with ld < 2.38 this
# fails if libruby.so contains .relr.dyn sections (SHT_RELR / type 0x13).
# The fix is in the Habitat plan (--pack-dyn-relocs=none at ruby build time).
if platform_family?("rhel", "fedora", "debian", "amazon", "suse")
  # Install MySQL/MariaDB client development headers
  mysql2_dev_pkg = value_for_platform_family(
    "debian" => "default-libmysqlclient-dev",
    "rhel" => node["platform_version"].to_i >= 9 ? "mariadb-connector-c-devel" : "mariadb-devel",
    "fedora" => "mariadb-devel",
    "suse" => "libmariadb-devel",
    "amazon" => node["platform_version"].to_i >= 2023 ? "mariadb105-devel" : "mariadb-devel"
  )

  build_pkgs = value_for_platform_family(
    "debian" => %w{build-essential},
    "rhel" => %w{gcc make glibc-devel},
    "fedora" => %w{gcc make glibc-devel},
    "suse" => %w{gcc make},
    "amazon" => %w{gcc make glibc-devel}
  )

  package build_pkgs
  package mysql2_dev_pkg

  chef_gem "mysql2" do
    compile_time false
  end
end
