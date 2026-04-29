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
  "debian" => %w{build-essential},
  "rhel" => %w{gcc make glibc-devel},
  "fedora" => %w{gcc make glibc-devel},
  "suse" => %w{gcc make},
  "amazon" => %w{gcc make glibc-devel}
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
# Rocky/Alma/Oracle Linux 9+ (RHEL family >= 9) replaced mariadb-devel with
# mariadb-connector-c-devel in AppStream; v8 still uses mariadb-devel.
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

# The Hab Ruby on some platforms was compiled against Hab glibc 2.41 whose
# libm.so.6 uses newer ELF .relr.dyn sections (SHT_RELR type 0x13) that the
# system binutils ld on RHEL 8/9 x86_64 and Debian 11 cannot parse when
# resolving transitive link-time dependencies. Ruby 3.4's mkmf.rb checks
# ENV['LDFLAGS'] as a fallback (via arg_config), so we prepend system library
# dirs as -rpath-link: the linker will then find the system libm.so.6 first
# (before the incompatible Hab glibc copy) when building native extensions.
# At runtime the Hab dynamic linker correctly resolves glibc via LD_LIBRARY_PATH.
ruby_block "fix-hab-glibc-ldflags-for-gem-builds" do
  block do
    require "rbconfig"
    existing = (RbConfig::CONFIG["LDFLAGS"] || "").strip
    rpath_link_flags = %w{
      /usr/lib64 /lib64
      /usr/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu
      /usr/lib/aarch64-linux-gnu /lib/aarch64-linux-gnu
      /usr/lib
    }.select { |d| ::File.directory?(d) }
     .map    { |d| "-Wl,-rpath-link,#{d}" }
     .join(" ")
    ENV["LDFLAGS"] = "#{existing} #{rpath_link_flags}".strip
    Chef::Log.info("Set LDFLAGS for gem builds: #{ENV['LDFLAGS']}")
  end
end

# Pass explicit mysql_config path to extconf.rb via gem install's -- separator.
# This bypasses any PATH differences in the Habitat Ruby gem subprocess.
chef_gem "mysql2" do
  compile_time false
  options lazy {
    config = %w{/usr/bin/mysql_config /usr/bin/mariadb_config}.find { |p| ::File.executable?(p) }
    config ? "-- --with-mysql-config=#{config}" : nil
  }
  ignore_failure true
end

# After the gem install attempt, display the mkmf.log so we can see the exact
# gcc invocation and error if compilation failed.
execute "debug-mysql2-mkmf-log" do
  command "mkmf=$(find /hab/pkgs/core/ruby3_4 -name mkmf.log -path '*mysql2*' 2>/dev/null | head -1); " \
          "[ -f \"$mkmf\" ] && echo \"=== mkmf.log: $mkmf ===\" && cat \"$mkmf\" || " \
          "echo 'no mysql2 mkmf.log found'"
  action :run
  live_stream true
end

# Fail the converge explicitly if mysql2.so was not produced.
execute "verify-mysql2-so-exists" do
  command "find /hab/pkgs/core/ruby3_4 -name 'mysql2.so' 2>/dev/null | " \
          "grep -q . && echo 'mysql2 installed OK' || " \
          "{ echo 'ERROR: mysql2.so not found -- gem compilation failed; see mkmf.log above'; exit 1; }"
  action :run
end
