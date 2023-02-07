#
# Copyright 2022 YOUR NAME
#
# All Rights Reserved.
#

name "universal-package"
maintainer "Progress Software, Inc."
homepage "https://chef.io"

install_dir "#{default_root}/#{name}"

build_version Omnibus::BuildVersion.semver
build_iteration 1

# Creates required build directories
dependency "preparation"
dependency "package-creator"

# universal-package dependencies/components
# dependency "somedep"

exclude "**/.git"
exclude "**/bundler/git"

package :pkg do
  identifier "com.getchef.pkg.universal-chef-client"
  signing_identity "Chef Software, Inc. (EU3VF8YLX2)"
end

compress :dmg