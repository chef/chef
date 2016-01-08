#
# Copyright 2014 Chef Software, Inc.
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

name "chefdk"
friendly_name "Chef Development Kit"
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.chef.io"

build_iteration 1
build_version '0.10.0'

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir "#{default_root}/opscode/#{name}"
else
  install_dir "#{default_root}/#{name}"
end

# Uncomment to pin the chef version
override :chef,             version: "master"
override :ohai,             version: "master"
override :chefdk,           version: "master"
override :inspec,           version: "master"
override :'kitchen-inspec', version: "v0.10.0"
# We should do a gem release of berkshelf and TK
# before releasing chefdk.
override :berkshelf,      version: "master"
override :'test-kitchen', version: "v1.5.0.rc.1"

override :'knife-windows', version: "v1.1.1"
override :'knife-spork',   version: "1.5.0"
override :fauxhai,         version: "v3.0.1"
override :chefspec,        version: "v4.5.0"

override :bundler,        version: "1.10.6"
override :'chef-vault',   version: "v2.6.1"

# TODO: Can we bump default versions in omnibus-software?
override :libedit,        version: "20130712-3.1"
override :libtool,        version: "2.4.2"
override :libxml2,        version: "2.9.1"
override :libxslt,        version: "1.1.28"

override :ruby,           version: "2.1.6"
######
# Ruby 2.1/2.2 has an error on Windows - HTTPS gem downloads aren't working
# https://bugs.ruby-lang.org/issues/11033
# Going to leave 2.1.5 for now since there is a workaround
override :'ruby-windows', version: "2.1.6"
override :'ruby-windows-devkit', version: "4.7.2-20130224"
######

######
# This points to jay's patched version for now to avoid a security
# vulnerability and to allow pry to get installed on windows builds.
# See the software definition for details.
if windows?
  override :rubygems,     version: "jdm/2.4.8-patched"
else
  override :rubygems,     version: "2.4.8"
end

override :rubocop, version: "v0.35.1"

override :'kitchen-vagrant', version: "v0.19.0"
override :'winrm-transport', version: "v1.0.3"
override :yajl,           version: "1.2.1"
override :zlib,           version: "1.2.8"

# NOTE: the base chef-provisioning gem is a dependency of chef-dk (the app).
# Manage the chef-provisioning version via chef-dk.gemspec.
override :'chef-provisioning-aws', version: "v1.7.0"
override :'chef-provisioning-azure', version: "v0.4.0"
override :'chef-provisioning-fog', version: "v0.15.0"
override :'chef-provisioning-vagrant', version: "v0.10.0"

dependency "preparation"
dependency "chefdk"
dependency "chef-provisioning-aws"
dependency "chef-provisioning-fog"
dependency "chef-provisioning-vagrant"
dependency "chef-provisioning-azure"
dependency "rubygems-customization"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.chefdk"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end

package :msi do
  fast_msi  true
  upgrade_code "AB1D6FBD-F9DC-4395-BDAD-26C4541168E7"
  signing_identity "F74E1A68005E8A9C465C3D2FF7B41F3988F0EA09", machine_store: true
  wix_light_extension "WixUtilExtension"
end

compress :dmg
