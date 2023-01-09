name "chef-foundation"
license "Apache-2.0"
license_file "LICENSE"

# Grab accompanying notice file.
# So that Open4/deep_merge/diff-lcs disclaimers are present in Omnibus LICENSES tree.
license_file "NOTICE"
# default_version "2.1.2"

# license "BSD-3-Clause"
# license_file "../package/COPYING"
skip_transitive_dependency_licensing true

# # version_list: url=http://smarden.org/runit/ filter=*.tar.gz

# version("2.1.2") { source sha256: "6fd0160cb0cf1207de4e66754b6d39750cff14bb0aa66ab49490992c0c47ba18" }
# version("2.1.1") { source sha256: "ffcf2d27b32f59ac14f2d4b0772a3eb80d9342685a2042b7fbbc472c07cf2a2c" }

# source url: "http://smarden.org/runit/runit-#{version}.tar.gz"

if windows?
  source path: "c:/opscode/chef"
else
  source path: "/opt/chef"
end

relative_path "chef-foundation"

build do
  sync "#{project_dir}", "#{install_dir}"
end