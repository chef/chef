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

# Native gem runtime-linking test — validates that a chef_gem's compiled
# extension can dlopen its shared library dependency at runtime under
# Habitat's scoped LD_LIBRARY_PATH / -z nodefaultlib linking.
# See https://github.com/sous-chefs/postgresql/issues/833: pg_ext.so links
# against libpq.so.5, and unlike a build-time link failure (mysql2 above),
# this only surfaces when `require "pg"` actually runs inside chef-client.
if platform_family?("rhel", "fedora", "debian", "amazon", "suse")
  libpq_dev_pkg = value_for_platform_family(
    "debian" => "libpq-dev",
    "rhel" => "libpq-devel",
    "fedora" => "libpq-devel",
    "suse" => "postgresql-devel",
    "amazon" => "libpq-devel"
  )

  package libpq_dev_pkg

  chef_gem "pg" do
    compile_time false
  end

  # Forces pg_ext.so to load in this chef-client process, reproducing the
  # LD_LIBRARY_PATH isolation failure from #833 if it regresses.
  ruby_block "require pg gem" do
    block { require "pg" }
  end
end
