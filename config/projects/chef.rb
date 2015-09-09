#
# Copyright 2012-2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "chef"
friendly_name "Chef Client"
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.chef.io"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef'

  # Output a SemVer compliant version string
  output_format :semver
end

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir  "#{default_root}/opscode/#{name}"
  package_name "chef-client"
else
  install_dir "#{default_root}/#{name}"
end

override :bundler,        version: "1.10.6"
override :ruby,           version: "2.1.6"

override :'ruby-windows', version: "2.0.0-p645"
override :rubygems,       version: "2.4.4"

# Chef Release version pinning
override :chef, version: ENV['CHEF_VERSION'] || "master"
override :ohai, version: ENV['OHAI_VERSION'] || "master"


dependency "preparation"
dependency "chef"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.chef"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end
compress :dmg

package :msi do
  upgrade_code "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"
  wix_candle_extension 'WixUtilExtension'
  signing_identity "F74E1A68005E8A9C465C3D2FF7B41F3988F0EA09", machine_store: true
end
